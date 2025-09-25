package api_test

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"reflect"
	"sort"

	"github.com/google/go-cmp/cmp"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
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
		apiEndpoint:        baseURL + "/api/objects/signature",
		schemaEndpoint:     baseURL + "/schema/objects/signature",
		sampleEndpoint:     baseURL + "/sample/objects/signature",
		validationEndpoint: baseURL + "/api/validate/object/signature",
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

var _ = Describe("API", func() {
	Describe("Object API Responses", func() {
		for _, tc := range testCases {
			tc := tc
			It("should match API response with expected JSON for "+tc.apiEndpoint, func() {
				expectedBytes, err := os.ReadFile(tc.jsonPath)
				Expect(err).NotTo(HaveOccurred(), "Failed to read expected JSON file")

				var expected map[string]interface{}
				Expect(json.Unmarshal(expectedBytes, &expected)).To(Succeed(), "Failed to unmarshal expected JSON")

				resp, err := http.Get(tc.apiEndpoint)
				Expect(err).NotTo(HaveOccurred(), "Failed to GET API")
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK), "Unexpected status code")

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred(), "Failed to read response body")

				var actual map[string]interface{}
				Expect(json.Unmarshal(respBytes, &actual)).To(Succeed(), "Failed to unmarshal response JSON")

				for _, field := range []string{"caption", "extends", "name", "description"} {
					expVal, expOk := expected[field]
					actVal, actOk := actual[field]
					if (!expOk && !actOk) || (expVal == nil && actVal == nil) {
						continue
					}
					Expect(expOk && actOk && expVal == actVal).To(BeTrue(),
						"Field %q mismatch: expected %v, got %v", field, expVal, actVal)
				}

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
				Expect(reflect.DeepEqual(expAttrNames, actAttrNames)).To(BeTrue(),
					"Attribute names mismatch:\nexpected: %v\ngot:      %v", expAttrNames, actAttrNames)
			})
		}
	})

	Describe("Sample Object Validation", func() {
		expectedValidate := map[string]interface{}{
			"errors":        []interface{}{},
			"warnings":      []interface{}{},
			"error_count":   float64(0),
			"warning_count": float64(0),
		}
		for _, tc := range testCases {
			tc := tc
			It("should validate sample object for "+tc.validationEndpoint, func() {
				sampleResp, err := http.Get(tc.sampleEndpoint)
				Expect(err).NotTo(HaveOccurred(), "Failed to GET sample")
				defer sampleResp.Body.Close()
				Expect(sampleResp.StatusCode).To(Equal(http.StatusOK), "Unexpected status code for sample")

				sampleBytes, err := io.ReadAll(sampleResp.Body)
				Expect(err).NotTo(HaveOccurred(), "Failed to read sample body")

				var sampleObj interface{}
				Expect(json.Unmarshal(sampleBytes, &sampleObj)).To(Succeed(), "Sample is not valid JSON")

				req, err := http.NewRequest("POST", tc.validationEndpoint, bytes.NewReader(sampleBytes))
				Expect(err).NotTo(HaveOccurred(), "Failed to create POST request")
				req.Header.Set("Content-Type", "application/json")
				resp2, err := http.DefaultClient.Do(req)
				Expect(err).NotTo(HaveOccurred(), "Failed to POST to validate endpoint")
				defer resp2.Body.Close()
				Expect(resp2.StatusCode).To(Equal(http.StatusOK), "Unexpected status code for validate endpoint")

				validateBytes, err := io.ReadAll(resp2.Body)
				Expect(err).NotTo(HaveOccurred(), "Failed to read validate response body")

				var validateResp map[string]interface{}
				Expect(json.Unmarshal(validateBytes, &validateResp)).To(Succeed(), "Validate response is not valid JSON")

				if !reflect.DeepEqual(validateResp, expectedValidate) {
					diff := cmp.Diff(expectedValidate, validateResp)
					GinkgoWriter.Printf("Validate response does not match expected.\nDiff:\n%s\n", diff)
				}
				Expect(validateResp).To(Equal(expectedValidate))
			})
		}
	})

	Describe("Sample Object Against Schema", func() {
		for _, tc := range testCases {
			tc := tc
			It("should validate sample object against schema for "+tc.schemaEndpoint, func() {
				resp, err := http.Get(tc.schemaEndpoint)
				Expect(err).NotTo(HaveOccurred(), "Failed to GET schema")
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK), "Unexpected status code for schema")

				schemaBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred(), "Failed to read schema body")

				resp2, err := http.Get(tc.sampleEndpoint)
				Expect(err).NotTo(HaveOccurred(), "Failed to GET sample")
				defer resp2.Body.Close()
				Expect(resp2.StatusCode).To(Equal(http.StatusOK), "Unexpected status code for sample")

				sampleBytes, err := io.ReadAll(resp2.Body)
				Expect(err).NotTo(HaveOccurred(), "Failed to read sample body")

				schemaLoader := gojsonschema.NewBytesLoader(schemaBytes)
				documentLoader := gojsonschema.NewBytesLoader(sampleBytes)
				result, err := gojsonschema.Validate(schemaLoader, documentLoader)
				Expect(err).NotTo(HaveOccurred(), "Failed to validate sample against schema")
				if !result.Valid() {
					for _, desc := range result.Errors() {
						GinkgoWriter.Printf("- %s\n", desc)
					}
				}
				Expect(result.Valid()).To(BeTrue(), "Sample does not validate against schema")
			})
		}
	})
})
