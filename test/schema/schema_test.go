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

type entityTypeData struct {
	names      map[string][]string
	categories []string
	extends    []struct {
		extValue string
		filePath string
	}
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

	// JSON validation gating
	var errors []string
	for _, file := range cache.Files {
		if filepath.Ext(file.Path) != ".json" {
			continue
		}
		relPath, _ := filepath.Rel(schemaDir, file.Path)
		var js interface{}
		if err := json.Unmarshal(file.Data, &js); err != nil {
			errors = append(errors, fmt.Sprintf("Invalid JSON in file %s: %s", relPath, err))
		}
	}
	if len(errors) > 0 {
		Fail("JSON validation failed:\n" + strings.Join(errors, "\n"))
	}
})

var _ = Describe("Metaschema validation", func() {
	It("should validate all files against their metaschema", func() {
		var errors []string

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

			if err := ValidateDataAgainstSchema(found.Data, target.Schema, target.File); err != nil {
				errors = append(errors, fmt.Sprintf("File %s failed validation: %s", target.File, err))
			}
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
				if err := ValidateDataAgainstSchema(file.Data, target.Schema, file.Path); err != nil {
					errors = append(errors, fmt.Sprintf("File %s failed validation: %s", file.Path, err))
				}
			}
		}

		if len(errors) > 0 {
			Fail("Errors found:\n" + strings.Join(errors, "\n"))
		}
	})
})

var _ = Describe("JSON content checks", func() {
	targets := []struct {
		Dir          string
		CategoryFile string
	}{
		{Dir: filepath.Join(schemaDir, "skills"), CategoryFile: filepath.Join(schemaDir, "skill_categories.json")},
		{Dir: filepath.Join(schemaDir, "domains"), CategoryFile: filepath.Join(schemaDir, "domain_categories.json")},
		{Dir: filepath.Join(schemaDir, "modules"), CategoryFile: filepath.Join(schemaDir, "module_categories.json")},
		{Dir: filepath.Join(schemaDir, "objects"), CategoryFile: ""},
	}
	var typeData map[string]*entityTypeData

	BeforeEach(func() {
		typeData = make(map[string]*entityTypeData)
		for _, folder := range targets {
			dir := folder.Dir
			data := &entityTypeData{
				names:      make(map[string][]string),
				categories: []string{"other"},
				extends: []struct {
					extValue string
					filePath string
				}{},
			}
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

				if name, ok := js["name"].(string); ok && name != "" {
					data.names[name] = append(data.names[name], file.Path)
				}

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
			typeData[folder.Dir] = data
		}
	})

	It("should have unique names within each entity type", func() {
		var errors []string
		for folder, data := range typeData {
			for name, filePaths := range data.names {
				if len(filePaths) > 1 {
					errors = append(errors, fmt.Sprintf("Duplicate name '%s' found in %s: %v", name, folder, filePaths))
				}
			}
		}
		if len(errors) > 0 {
			Fail("Errors found:\n" + strings.Join(errors, "\n"))
		}
	})

	It("should have all 'extends' values refer to a valid name within the same entity type", func() {
		var errors []string
		for folder, data := range typeData {
			for _, ext := range data.extends {
				if _, found := data.names[ext.extValue]; !found {
					errors = append(errors, fmt.Sprintf("extends value '%s' in file %s does not match any defined name in %s", ext.extValue, ext.filePath, folder))
				}
			}
		}
		if len(errors) > 0 {
			Fail("Errors found:\n" + strings.Join(errors, "\n"))
		}
	})

	It("should have 'category' values within allowed categories if a category file is present", func() {
		var errors []string
		for folder, data := range typeData {
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
					if !ok {
						errors = append(errors, fmt.Sprintf("'category' field in %s is not a string", file.Path))
					}
					if _, found := allowed[catStr]; !found {
						errors = append(errors, fmt.Sprintf("'category' value '%s' in file %s is not allowed by %s", catStr, file.Path, folder))
					}
				}
			}
		}
		if len(errors) > 0 {
			Fail("Errors found:\n" + strings.Join(errors, "\n"))
		}
	})
})

var _ = Describe("Attribute dictionary consistency", func() {
	It("should have all attributes used in files defined in the dictionary", func() {
		folders := []string{"objects", "skills", "domains", "modules"}
		var attributesInFiles map[string][]string
		var attributesInDict map[string]struct{}

		attributesInFiles = make(map[string][]string)
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
	if len(warnings) > 0 && os.Getenv("GITHUB_ACTIONS") != "true" {
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
	// Also print as a GitHub Actions warning annotation if running in CI
	if os.Getenv("GITHUB_ACTIONS") == "true" {
		fmt.Printf("::warning::%s\n", msg)
	}
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
