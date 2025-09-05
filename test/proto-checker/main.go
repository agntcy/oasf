package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/emicklei/proto"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

// JsonSchema represents the structure of your custom JSON schema
type JsonSchema struct {
	Caption     string                   `json:"caption"`
	Description string                   `json:"description"`
	Extends     string                   `json:"extends"`
	Name        string                   `json:"name"`
	Attributes  map[string]JsonAttribute `json:"attributes"`
}

// JsonAttribute represents an attribute within the JSON schema
type JsonAttribute struct {
	Caption     string `json:"caption"`
	Description string `json:"description"`
	Requirement string `json:"requirement"`
	Reference   string `json:"reference,omitempty"`
}

// ProtoField represents a parsed field from a .proto file
type ProtoField struct {
	Name        string
	Type        string // Will include "repeated " prefix if it's a repeated field, or "map<...>"
	Comment     string // Concatenated comments for the field
	FieldNumber int
}

// ProtoMessage represents a parsed message from a .proto file
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
	if v.ProtoMessage.Name == "" { // Only capture the first (main) message encountered
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

func main() {
	if len(os.Args) != 3 {
		fmt.Println("Usage: go run main.go <json_file_path> <proto_file_path>")
		os.Exit(1)
	}

	jsonFile := os.Args[1]
	protoFile := os.Args[2]

	jsonSchemaData, err := parseJsonSchema(jsonFile)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	protoMessageData, err := parseProtoFile(protoFile)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	errors, warnings := compareSchemas(jsonSchemaData, protoMessageData)

	if len(errors) > 0 {
		fmt.Println("Schema Synchronization FAILED with ERRORS:")
		for _, err := range errors {
			fmt.Printf("- ERROR: %s\n", err)
		}
		os.Exit(1)
	}
	if len(warnings) > 0 {
		fmt.Println("\nSchema Synchronization found WARNINGS:")
		for _, warn := range warnings {
			fmt.Printf("- WARNING: %s\n", warn)
		}
	}

	if len(errors) == 0 && len(warnings) == 0 {
		fmt.Printf("Schema Synchronization PASSED: %s JSON and Proto files are consistent.\n", jsonSchemaData.Caption)
	} else if len(errors) == 0 && len(warnings) > 0 {
		fmt.Println("Schema Synchronization PASSED with WARNINGS.")
	}
}
