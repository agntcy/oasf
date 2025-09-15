package schema_test

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	"github.com/xeipuuv/gojsonschema"
)

const schemaDir = "../../schema"

type SchemaFile struct {
	Path string
	Data []byte
}

type SchemaCache struct {
	Files []SchemaFile
	Dirs  []string
}

var cache SchemaCache
var warnings []string

var _ = BeforeSuite(func() {
	var files []SchemaFile
	var dirs []string
	err := filepath.WalkDir(schemaDir, func(path string, d os.DirEntry, err error) error {
		Expect(err).NotTo(HaveOccurred())
		if d.IsDir() {
			dirs = append(dirs, path)
			return nil
		}
		data, err := os.ReadFile(path)
		Expect(err).NotTo(HaveOccurred())
		files = append(files, SchemaFile{Path: path, Data: data})
		return nil
	})
	Expect(err).NotTo(HaveOccurred())
	fmt.Printf("Loaded %d files in %d directories from %s\n", len(files), len(dirs), schemaDir)
	cache = SchemaCache{Files: files, Dirs: dirs}
})

var _ = Describe("OASF schema", func() {
	It("should have all JSON files valid", func() {
		for _, file := range cache.Files {
			if filepath.Ext(file.Path) != ".json" {
				continue
			}
			relPath, _ := filepath.Rel(schemaDir, file.Path)
			var js interface{}
			err := json.Unmarshal(file.Data, &js)
			Expect(err).NotTo(HaveOccurred(), "Invalid JSON in file %s", relPath)
		}
	})
})

var _ = Describe("Metaschema validation", func() {
	It("should validate all files against their metaschema", func() {
		metaschemaDir := filepath.Join(schemaDir, "metaschema")
		files := []struct {
			File   string
			Schema string
		}{
			{File: filepath.Join(schemaDir, "dictionary.json"), Schema: filepath.Join(metaschemaDir, "dictionary.schema.json")},
		}

		for _, target := range files {
			var found *SchemaFile
			for _, f := range cache.Files {
				if f.Path == target.File {
					found = &f
					break
				}
			}
			Expect(found).NotTo(BeNil(), "File %s not found in cache", target.File)

			err := ValidateDataAgainstSchema(found.Data, target.Schema, target.File)
			Expect(err).NotTo(HaveOccurred())
		}

		directories := []struct {
			Dir    string
			Schema string
		}{
			{Dir: filepath.Join(schemaDir, "domains"), Schema: filepath.Join(metaschemaDir, "class.schema.json")},
			{Dir: filepath.Join(schemaDir, "skills"), Schema: filepath.Join(metaschemaDir, "class.schema.json")},
			{Dir: filepath.Join(schemaDir, "modules"), Schema: filepath.Join(metaschemaDir, "class.schema.json")},
			{Dir: filepath.Join(schemaDir, "objects"), Schema: filepath.Join(metaschemaDir, "object.schema.json")},
			{Dir: filepath.Join(schemaDir, "profiles"), Schema: filepath.Join(metaschemaDir, "profile.schema.json")},
			{Dir: filepath.Join(schemaDir, "extensions"), Schema: filepath.Join(metaschemaDir, "extension.schema.json")},
		}

		for _, target := range directories {
			dirInfo, err := os.Stat(target.Dir)
			if err != nil || !dirInfo.IsDir() {
				AddWarning("%s directory does not exist\n", target.Dir)
				continue
			}

			var filesInDir []SchemaFile
			for _, file := range cache.Files {
				if strings.HasPrefix(file.Path, target.Dir+string(os.PathSeparator)) && filepath.Ext(file.Path) == ".json" {
					filesInDir = append(filesInDir, file)
				}
			}

			for _, file := range filesInDir {
				err := ValidateDataAgainstSchema(file.Data, target.Schema, file.Path)
				Expect(err).NotTo(HaveOccurred())
			}
		}
	})
})

type entityTypeData struct {
	names      map[string]string
	categories []string
	extends    []struct {
		extValue string
		filePath string
	}
}

var _ = Describe("JSON content checks", func() {
	targets := []struct {
		Dir          string
		CategoryFile string
	}{
		{Dir: filepath.Join(schemaDir, "skills"), CategoryFile: filepath.Join(schemaDir, "main_skills.json")},
		{Dir: filepath.Join(schemaDir, "domains"), CategoryFile: filepath.Join(schemaDir, "main_domains.json")},
		{Dir: filepath.Join(schemaDir, "modules"), CategoryFile: filepath.Join(schemaDir, "main_modules.json")},
		{Dir: filepath.Join(schemaDir, "objects"), CategoryFile: ""},
	}
	catData := make(map[string]*entityTypeData)

	BeforeEach(func() {
		for _, folder := range targets {
			dir := folder.Dir
			data := &entityTypeData{
				names:      make(map[string]string),
				categories: []string{"other"},
				extends: []struct {
					extValue string
					filePath string
				}{},
			}
			// Load allowed categories if CategoryFile is set
			if folder.CategoryFile != "" {
				raw, err := os.ReadFile(folder.CategoryFile)
				Expect(err).NotTo(HaveOccurred(), "Failed to read category file %s", folder.CategoryFile)
				var cat map[string]interface{}
				err = json.Unmarshal(raw, &cat)
				Expect(err).NotTo(HaveOccurred(), "Invalid JSON in category file %s", folder.CategoryFile)
				if attrs, ok := cat["attributes"].(map[string]interface{}); ok {
					for k := range attrs {
						data.categories = append(data.categories, k)
					}
				}
			}
			for _, file := range cache.Files {
				if !strings.HasPrefix(file.Path, dir+string(os.PathSeparator)) || filepath.Ext(file.Path) != ".json" {
					continue
				}
				var js map[string]interface{}
				err := json.Unmarshal(file.Data, &js)
				Expect(err).NotTo(HaveOccurred(), "Invalid JSON in file %s", file.Path)

				// Collect name
				if name, ok := js["name"].(string); ok && name != "" {
					data.names[name] = file.Path
				}

				// Collect extends
				if ext, ok := js["extends"]; ok {
					switch v := ext.(type) {
					case string:
						data.extends = append(data.extends, struct {
							extValue string
							filePath string
						}{v, file.Path})
					case []interface{}:
						for _, item := range v {
							if s, ok := item.(string); ok {
								data.extends = append(data.extends, struct {
									extValue string
									filePath string
								}{s, file.Path})
							}
						}
					}
				}
			}
			catData[folder.Dir] = data
		}
	})

	It("should have unique names within each entity type", func() {
		for folder, data := range catData {
			seen := make(map[string]string)
			for name, filePath := range data.names {
				if prevFile, exists := seen[name]; exists {
					Fail(fmt.Sprintf("Duplicate name '%s' found in %s: %s and %s", name, folder, prevFile, filePath))
				}
				seen[name] = filePath
			}
		}
	})

	It("should have all 'extends' values refer to a valid name within the same entity type", func() {
		for folder, data := range catData {
			for _, ext := range data.extends {
				_, found := data.names[ext.extValue]
				Expect(found).To(BeTrue(), "extends value '%s' in file %s does not match any defined name in %s", ext.extValue, ext.filePath, folder)
			}
		}
	})

	It("should have 'category' values within allowed categories if a category file is present", func() {
		for folder, data := range catData {
			if len(data.categories) == 0 {
				continue
			}
			allowed := make(map[string]struct{}, len(data.categories))
			for _, cat := range data.categories {
				allowed[cat] = struct{}{}
			}
			for _, file := range cache.Files {
				if !strings.HasPrefix(file.Path, folder+string(os.PathSeparator)) || filepath.Ext(file.Path) != ".json" {
					continue
				}
				var js map[string]interface{}
				err := json.Unmarshal(file.Data, &js)
				Expect(err).NotTo(HaveOccurred(), "Invalid JSON in file %s", file.Path)
				if catVal, ok := js["category"]; ok {
					catStr, ok := catVal.(string)
					Expect(ok).To(BeTrue(), "'category' field in %s is not a string", file.Path)
					_, found := allowed[catStr]
					Expect(found).To(BeTrue(), "'category' value '%s' in file %s is not allowed by %s", catStr, file.Path, folder)
				}
			}
		}
	})
})

var _ = Describe("Attribute dictionary consistency", Ordered, func() {
	It("should have all attributes used in files defined in the dictionary", func() {
		folders := []string{"objects", "skills", "domains", "modules"}
		var attributesInFiles map[string][]string
		var attributesInDict map[string]struct{}

		attributesInFiles = make(map[string][]string)
		// Collect all attributes from files, mapping attribute (or reference) -> []filePath
		for _, folder := range folders {
			dir := filepath.Join(schemaDir, folder)
			for _, file := range cache.Files {
				if !strings.HasPrefix(file.Path, dir+string(os.PathSeparator)) || filepath.Ext(file.Path) != ".json" {
					continue
				}
				var js map[string]interface{}
				err := json.Unmarshal(file.Data, &js)
				Expect(err).NotTo(HaveOccurred(), "Invalid JSON in file %s", file.Path)
				if attrs, ok := js["attributes"].(map[string]interface{}); ok {
					for attrKey, attrVal := range attrs {
						attrName := attrKey
						if attrMap, ok := attrVal.(map[string]interface{}); ok {
							if ref, ok := attrMap["reference"].(string); ok && ref != "" {
								attrName = ref
							}
						}
						attributesInFiles[attrName] = append(attributesInFiles[attrName], file.Path)
					}
				}
			}
		}

		// Collect all attributes from dictionary.json
		dictPath := filepath.Join(schemaDir, "dictionary.json")
		dictRaw, err := os.ReadFile(dictPath)
		Expect(err).NotTo(HaveOccurred(), "Failed to read dictionary.json")
		var dict map[string]interface{}
		err = json.Unmarshal(dictRaw, &dict)
		Expect(err).NotTo(HaveOccurred(), "Invalid JSON in dictionary.json")
		dictAttrs, ok := dict["attributes"].(map[string]interface{})
		Expect(ok).To(BeTrue(), "'attributes' object not found in dictionary.json")

		attributesInDict = make(map[string]struct{})
		for attr := range dictAttrs {
			attributesInDict[attr] = struct{}{}
		}

		for attr := range attributesInDict {
			if _, found := attributesInFiles[attr]; !found {
				AddWarning("Attribute '%s' in dictionary.json is not used in any file", attr)
			}
		}

		var errors []string
		for attr, files := range attributesInFiles {
			if _, found := attributesInDict[attr]; !found {
				errors = append(errors, fmt.Sprintf("Attribute '%s' used in files but not found in dictionary.json. Used in: %v", attr, files))
			}
		}
		if len(errors) > 0 {
			Fail("Errors found:\n" + strings.Join(errors, "\n"))
		}
	})
})

var _ = AfterSuite(func() {
	if len(warnings) > 0 {
		const yellow = "\033[33m"
		const reset = "\033[0m"
		fmt.Printf("%s\n", yellow)
		for _, w := range warnings {
			fmt.Printf("WARNING: %s\n", w)
		}
		fmt.Printf("%s", reset)
	}
})

func AddWarning(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	warnings = append(warnings, msg)
}

func ValidateDataAgainstSchema(data []byte, schemaPath, filePath string) error {
	absSchemaPath, err := filepath.Abs(schemaPath)
	if err != nil {
		return fmt.Errorf("failed to get absolute path for schema: %w", err)
	}
	schemaLoader := gojsonschema.NewReferenceLoader("file://" + filepath.ToSlash(absSchemaPath))
	docLoader := gojsonschema.NewBytesLoader(data)
	result, err := gojsonschema.Validate(schemaLoader, docLoader)
	relPath, _ := filepath.Rel(schemaDir, filePath)
	if err != nil {
		return fmt.Errorf("validation error for %s: %w", relPath, err)
	}
	if !result.Valid() {
		var sb strings.Builder
		for _, desc := range result.Errors() {
			sb.WriteString(desc.String())
			sb.WriteString("\n")
		}
		return fmt.Errorf("schema validation failed for %s:\n%s", relPath, sb.String())
	}
	return nil
}
