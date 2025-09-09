package api

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"reflect"
	"sort"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/xeipuuv/gojsonschema"
)

const baseURL = "http://localhost:8080"

type objectTestCase struct {
	jsonPath           string
	apiEndpoint        string
	schemaEndpoint     string
	sampleEndpoint     string
	validationEndpoint string
}

var testCases = []objectTestCase{
	{
		jsonPath:           "../../schema/objects/record.json",
		apiEndpoint:        baseURL + "/api/objects/record",
		schemaEndpoint:     baseURL + "/schema/objects/record",
		sampleEndpoint:     baseURL + "/sample/objects/record",
		validationEndpoint: baseURL + "/api/validate/object/record",
	},
	{
		jsonPath:           "../../schema/objects/locator.json",
		apiEndpoint:        baseURL + "/api/objects/locator",
		schemaEndpoint:     baseURL + "/schema/objects/locator",
		sampleEndpoint:     baseURL + "/sample/objects/locator",
		validationEndpoint: baseURL + "/api/validate/object/locator",
	},
	{
		jsonPath:           "../../schema/objects/signature.json",
		apiEndpoint:        baseURL + "/api/objects/record_signature",
		schemaEndpoint:     baseURL + "/schema/objects/record_signature",
		sampleEndpoint:     baseURL + "/sample/objects/record_signature",
		validationEndpoint: baseURL + "/api/validate/object/record_signature",
	},
	{
		jsonPath:           "../../schema/skills/base_skill.json",
		apiEndpoint:        baseURL + "/api/skills/base_skill",
		schemaEndpoint:     baseURL + "/schema/skills/base_skill",
		sampleEndpoint:     baseURL + "/sample/skills/base_skill",
		validationEndpoint: baseURL + "/api/validate/skill",
	},
	{
		jsonPath:           "../../schema/domains/base_domain.json",
		apiEndpoint:        baseURL + "/api/domains/base_domain",
		schemaEndpoint:     baseURL + "/schema/domains/base_domain",
		sampleEndpoint:     baseURL + "/sample/domains/base_domain",
		validationEndpoint: baseURL + "/api/validate/domain",
	},
	{
		jsonPath:           "../../schema/modules/base_module.json",
		apiEndpoint:        baseURL + "/api/modules/base_module",
		schemaEndpoint:     baseURL + "/schema/modules/base_module",
		sampleEndpoint:     baseURL + "/sample/modules/base_module",
		validationEndpoint: baseURL + "/api/validate/module",
	},
}

func TestObjectAPIResponses(t *testing.T) {
	for _, tc := range testCases {
		t.Run(tc.apiEndpoint, func(t *testing.T) {
			expectedBytes, err := os.ReadFile(tc.jsonPath)
			if err != nil {
				t.Fatalf("Failed to read expected JSON file: %v", err)
			}
			var expected map[string]interface{}
			if err := json.Unmarshal(expectedBytes, &expected); err != nil {
				t.Fatalf("Failed to unmarshal expected JSON: %v", err)
			}

			resp, err := http.Get(tc.apiEndpoint)
			if err != nil {
				t.Fatalf("Failed to GET API: %v", err)
			}
			defer resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("Unexpected status code: got %d, want %d", resp.StatusCode, http.StatusOK)
			}
			respBytes, err := io.ReadAll(resp.Body)
			if err != nil {
				t.Fatalf("Failed to read response body: %v", err)
			}
			var actual map[string]interface{}
			if err := json.Unmarshal(respBytes, &actual); err != nil {
				t.Fatalf("Failed to unmarshal response JSON: %v", err)
			}

			// Compare selected fields
			for _, field := range []string{"caption", "extends", "name", "description"} {
				expVal, expOk := expected[field]
				actVal, actOk := actual[field]
				if (!expOk && !actOk) || (expVal == nil && actVal == nil) {
					// Both missing or both nil: OK
					continue
				}
				if !expOk || !actOk || expVal != actVal {
					t.Errorf("Field %q mismatch: expected %v, got %v", field, expVal, actVal)
				}
			}

			// Compare attribute names
			getAttrNames := func(obj map[string]interface{}) []string {
				attrs, ok := obj["attributes"]
				if !ok {
					return nil
				}
				names := []string{}
				switch v := attrs.(type) {
				case map[string]interface{}:
					for k := range v {
						names = append(names, k)
					}
				case []interface{}:
					for _, attr := range v {
						if m, ok := attr.(map[string]interface{}); ok {
							for k := range m {
								names = append(names, k)
							}
						}
					}
				}
				sort.Strings(names)
				return names
			}

			expAttrNames := getAttrNames(expected)
			actAttrNames := getAttrNames(actual)
			if !reflect.DeepEqual(expAttrNames, actAttrNames) {
				t.Errorf("Attribute names mismatch:\nexpected: %v\ngot:      %v", expAttrNames, actAttrNames)
			}
		})
	}
}

func TestSampleObjectValidation(t *testing.T) {
	expectedValidate := map[string]interface{}{
		"errors":        []interface{}{},
		"warnings":      []interface{}{},
		"error_count":   float64(0),
		"warning_count": float64(0),
	}
	for _, tc := range testCases {
		t.Run(tc.validationEndpoint, func(t *testing.T) {
			// GET sample
			sampleResp, err := http.Get(tc.sampleEndpoint)
			if err != nil {
				t.Fatalf("Failed to GET sample: %v", err)
			}
			defer sampleResp.Body.Close()
			if sampleResp.StatusCode != http.StatusOK {
				t.Fatalf("Unexpected status code for sample: got %d, want %d", sampleResp.StatusCode, http.StatusOK)
			}
			sampleBytes, err := io.ReadAll(sampleResp.Body)
			if err != nil {
				t.Fatalf("Failed to read sample body: %v", err)
			}
			var sampleObj interface{}
			if err := json.Unmarshal(sampleBytes, &sampleObj); err != nil {
				t.Fatalf("Sample is not valid JSON: %v", err)
			}

			// POST to validate endpoint
			req, err := http.NewRequest("POST", tc.validationEndpoint, bytes.NewReader(sampleBytes))
			if err != nil {
				t.Fatalf("Failed to create POST request: %v", err)
			}
			req.Header.Set("Content-Type", "application/json")
			resp2, err := http.DefaultClient.Do(req)
			if err != nil {
				t.Fatalf("Failed to POST to validate endpoint: %v", err)
			}
			defer resp2.Body.Close()
			if resp2.StatusCode != http.StatusOK {
				t.Fatalf("Unexpected status code for validate endpoint: got %d, want %d", resp2.StatusCode, http.StatusOK)
			}
			validateBytes, err := io.ReadAll(resp2.Body)
			if err != nil {
				t.Fatalf("Failed to read validate response body: %v", err)
			}
			var validateResp map[string]interface{}
			if err := json.Unmarshal(validateBytes, &validateResp); err != nil {
				t.Fatalf("Validate response is not valid JSON: %v", err)
			}
			if !reflect.DeepEqual(validateResp, expectedValidate) {
				diff := cmp.Diff(expectedValidate, validateResp)
				t.Errorf("Validate response does not match expected.\nDiff:\n%s\n", diff)
			}
		})
	}
}

func TestSampleObjectAgainstSchema(t *testing.T) {
	for _, tc := range testCases {
		t.Run(tc.schemaEndpoint, func(t *testing.T) {
			// Download schema
			resp, err := http.Get(tc.schemaEndpoint)
			if err != nil {
				t.Fatalf("Failed to GET schema: %v", err)
			}
			defer resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				t.Fatalf("Unexpected status code for schema: got %d, want %d", resp.StatusCode, http.StatusOK)
			}
			schemaBytes, err := io.ReadAll(resp.Body)
			if err != nil {
				t.Fatalf("Failed to read schema body: %v", err)
			}

			// Download sample
			resp2, err := http.Get(tc.sampleEndpoint)
			if err != nil {
				t.Fatalf("Failed to GET sample: %v", err)
			}
			defer resp2.Body.Close()
			if resp2.StatusCode != http.StatusOK {
				t.Fatalf("Unexpected status code for sample: got %d, want %d", resp2.StatusCode, http.StatusOK)
			}
			sampleBytes, err := io.ReadAll(resp2.Body)
			if err != nil {
				t.Fatalf("Failed to read sample body: %v", err)
			}

			// Validate sample against schema
			schemaLoader := gojsonschema.NewBytesLoader(schemaBytes)
			documentLoader := gojsonschema.NewBytesLoader(sampleBytes)
			result, err := gojsonschema.Validate(schemaLoader, documentLoader)
			if err != nil {
				t.Fatalf("Failed to validate sample against schema: %v", err)
			}
			if !result.Valid() {
				for _, desc := range result.Errors() {
					t.Errorf("- %s\n", desc)
				}
				t.Fatalf("Sample does not validate against schema")
			}
		})
	}
}
