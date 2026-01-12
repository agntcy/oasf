package proto_test

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/emicklei/proto"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

type JsonSchema struct {
	Caption     string                   `json:"caption"`
	Description string                   `json:"description"`
	Extends     string                   `json:"extends"`
	Name        string                   `json:"name"`
	Attributes  map[string]JsonAttribute `json:"attributes"`
}

type JsonAttribute struct {
	Caption     string `json:"caption"`
	Description string `json:"description"`
	Requirement string `json:"requirement"`
	Reference   string `json:"reference,omitempty"`
}

type ProtoField struct {
	Name        string
	Type        string
	Comment     string
	FieldNumber int
}

type ProtoMessage struct {
	Name    string
	Fields  map[string]ProtoField
	Imports []string
}

func parseJsonSchema(filePath string) (JsonSchema, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return JsonSchema{}, fmt.Errorf("failed to read JSON file %s: %w", filePath, err)
	}
	var schema JsonSchema
	if err := json.Unmarshal(data, &schema); err != nil {
		return JsonSchema{}, fmt.Errorf("failed to unmarshal JSON file %s: %w", filePath, err)
	}
	return schema, nil
}

type protoVisitor struct {
	proto.NoopVisitor
	ProtoMessage *ProtoMessage
}

func (v *protoVisitor) VisitMessage(m *proto.Message) {
	if v.ProtoMessage.Name == "" {
		v.ProtoMessage.Name = m.Name
	}
	for _, each := range m.Elements {
		each.Accept(v)
	}
}

func (v *protoVisitor) VisitNormalField(f *proto.NormalField) {
	comment := ""
	if f.Comment != nil {
		comment = strings.Join(f.Comment.Lines, " ")
	}
	v.ProtoMessage.Fields[f.Name] = ProtoField{
		Name:        f.Name,
		Type:        f.Type,
		Comment:     comment,
		FieldNumber: f.Sequence,
	}
}

func (v *protoVisitor) VisitImport(i *proto.Import) {
	v.ProtoMessage.Imports = append(v.ProtoMessage.Imports, i.Filename)
}

func (v *protoVisitor) VisitOneofField(f *proto.OneOfField) {
	comment := ""
	if f.Comment != nil {
		comment = strings.Join(f.Comment.Lines, " ")
	}
	v.ProtoMessage.Fields[f.Name] = ProtoField{
		Name:        f.Name,
		Type:        f.Type,
		Comment:     comment,
		FieldNumber: f.Sequence,
	}
}

func (v *protoVisitor) VisitMapField(f *proto.MapField) {
	comment := ""
	if f.Comment != nil {
		comment = strings.Join(f.Comment.Lines, " ")
	}
	v.ProtoMessage.Fields[f.Name] = ProtoField{
		Name:        f.Name,
		Type:        f.Type,
		Comment:     comment,
		FieldNumber: f.Sequence,
	}
}

func parseProtoFile(filePath string) (ProtoMessage, error) {
	reader, err := os.Open(filePath)
	if err != nil {
		return ProtoMessage{}, fmt.Errorf("failed to open proto file %s: %w", filePath, err)
	}
	defer reader.Close()

	parser := proto.NewParser(reader)
	definition, err := parser.Parse()
	if err != nil {
		return ProtoMessage{}, fmt.Errorf("failed to parse proto file %s: %w", filePath, err)
	}

	protoMsg := ProtoMessage{
		Fields: make(map[string]ProtoField),
	}

	visitor := &protoVisitor{ProtoMessage: &protoMsg}
	definition.Accept(visitor)

	if protoMsg.Name == "" {
		return ProtoMessage{}, fmt.Errorf("no message definition found in proto file %s", filePath)
	}

	return protoMsg, nil
}

func compareSchemas(jsonSchema JsonSchema, protoMessage ProtoMessage) ([]string, []string) {
	var errors []string
	var warnings []string

	caser := cases.Title(language.English)
	expectedProtoName := caser.String(jsonSchema.Caption)
	if protoMessage.Name != expectedProtoName {
		errors = append(errors, fmt.Sprintf("Message name mismatch: JSON '%s' vs Proto '%s'. Expected Proto to be '%s'.", jsonSchema.Caption, protoMessage.Name, expectedProtoName))
	}

	jsonAttributes := jsonSchema.Attributes
	protoFields := protoMessage.Fields

	for attrName := range jsonAttributes {
		_, exists := protoFields[attrName]
		if !exists {
			errors = append(errors, fmt.Sprintf("JSON attribute '%s' is missing in Proto message '%s'.", attrName, protoMessage.Name))
			continue
		}
	}

	for fieldName := range protoFields {
		if _, exists := jsonAttributes[fieldName]; !exists {
			warnings = append(warnings, fmt.Sprintf("Proto field '%s' exists in Proto but is missing in JSON schema. Consider if this is intended.", fieldName))
		}
	}

	return errors, warnings
}

var _ = Describe("JsonSchema and Proto synchronization", func() {
	schemaRoot := "../../schema/"
	protoRoot := "../../proto/agntcy/oasf/types/v1/"

	type testCase struct {
		entityType string
		fileName   string
		protoPath  string
	}

	cases := []testCase{
		{"objects", "record.json", filepath.Join(protoRoot, "record.proto")},
		{"objects", "locator.json", filepath.Join(protoRoot, "locator.proto")},
		{"skills", "base_skill.json", filepath.Join(protoRoot, "skill.proto")},
		{"domains", "base_domain.json", filepath.Join(protoRoot, "domain.proto")},
		{"modules", "base_module.json", filepath.Join(protoRoot, "module.proto")},
	}

	for _, tc := range cases {
		jsonPath := filepath.Join(schemaRoot, tc.entityType, tc.fileName)
		It(fmt.Sprintf("should sync JSON schema %s and Proto %s", filepath.Base(jsonPath), filepath.Base(tc.protoPath)), func() {
			jsonSchemaData, err := parseJsonSchema(jsonPath)
			Expect(err).NotTo(HaveOccurred(), "Error parsing JSON: %v", err)

			// Handle extends
			if jsonSchemaData.Extends != "" {
				extendsPath := filepath.Join(schemaRoot, tc.entityType, jsonSchemaData.Extends+".json")
				extendedSchema, err := parseJsonSchema(extendsPath)
				Expect(err).NotTo(HaveOccurred(), "Error parsing extended JSON: %v", err)
				// Merge attributes: extended first, then main (main overrides)
				for k, v := range extendedSchema.Attributes {
					if _, exists := jsonSchemaData.Attributes[k]; !exists {
						jsonSchemaData.Attributes[k] = v
					}
				}
			}

			protoMessageData, err := parseProtoFile(tc.protoPath)
			Expect(err).NotTo(HaveOccurred(), "Error parsing Proto: %v", err)

			errors, warnings := compareSchemas(jsonSchemaData, protoMessageData)
			for _, warn := range warnings {
				GinkgoWriter.Printf("WARNING: %s\n", warn)
			}
			Expect(errors).To(BeEmpty(), "Errors: %v", errors)
		})
	}
})
