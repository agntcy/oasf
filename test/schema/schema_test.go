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
				PrintWarning("%s directory does not exist\n", target.Dir)
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

func PrintWarning(format string, args ...interface{}) {
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
