package schema_test

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
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
