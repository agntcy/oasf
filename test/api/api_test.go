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
	entityType         string
	fileName           string
	apiEndpoint        string
	schemaEndpoint     string
	sampleEndpoint     string
	validationEndpoint string
}

var testCases = []objectTestCase{
	{
		entityType:         "objects",
		fileName:           "record.json",
		apiEndpoint:        baseURL + "/api/objects/record",
		schemaEndpoint:     baseURL + "/schema/objects/record",
		sampleEndpoint:     baseURL + "/sample/objects/record",
		validationEndpoint: baseURL + "/api/validate/object/record",
	},
	{
		entityType:         "objects",
		fileName:           "locator.json",
		apiEndpoint:        baseURL + "/api/objects/locator",
		schemaEndpoint:     baseURL + "/schema/objects/locator",
		sampleEndpoint:     baseURL + "/sample/objects/locator",
		validationEndpoint: baseURL + "/api/validate/object/locator",
	},
}

var _ = Describe("API", func() {
	Describe("Object API Responses", func() {
		for _, tc := range testCases {
			tc := tc
			It("should match API response with expected JSON for "+tc.apiEndpoint, func() {
				jsonPath := "../../schema/" + tc.entityType + "/" + tc.fileName
				expectedBytes, err := os.ReadFile(jsonPath)
				Expect(err).NotTo(HaveOccurred(), "Failed to read expected JSON file")

				var expected map[string]interface{}
				Expect(json.Unmarshal(expectedBytes, &expected)).To(Succeed(), "Failed to unmarshal expected JSON")

				// Handle extends
				if ext, ok := expected["extends"].(string); ok && ext != "" {
					extendsPath := "../../schema/" + tc.entityType + "/" + ext + ".json"
					extendsBytes, err := os.ReadFile(extendsPath)
					Expect(err).NotTo(HaveOccurred(), "Failed to read extended JSON file")
					var parent map[string]interface{}
					Expect(json.Unmarshal(extendsBytes, &parent)).To(Succeed(), "Failed to unmarshal extended JSON")
					// Merge attributes: parent first, then child (child overrides)
					parentAttrs, _ := parent["attributes"].(map[string]interface{})
					childAttrs, _ := expected["attributes"].(map[string]interface{})
					mergedAttrs := map[string]interface{}{}
					for k, v := range parentAttrs {
						mergedAttrs[k] = v
					}
					for k, v := range childAttrs {
						mergedAttrs[k] = v
					}
					expected["attributes"] = mergedAttrs
				}

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

	Describe("GET Endpoints Health Check", func() {
		// Test IDs to use for parameterized endpoints
		testSkillID := "base_skill"
		testDomainID := "base_domain"
		testModuleID := "base_module"
		testSkillCategoryID := "natural_language_processing"
		testDomainCategoryID := "healthcare"
		testModuleCategoryID := "core"
		testObjectID := "record"
		// testProfileID := "default" // Uncomment and set to a valid profile ID if available

		getEndpoints := []struct {
			name string
			url  string
		}{
			// Root and category pages
			{"root", baseURL + "/"},
			{"skill_categories", baseURL + "/skill_categories"},
			{"skill_categories_by_id", baseURL + "/skill_categories/" + testSkillCategoryID},
			{"domain_categories", baseURL + "/domain_categories"},
			{"domain_categories_by_id", baseURL + "/domain_categories/" + testDomainCategoryID},
			{"module_categories", baseURL + "/module_categories"},
			{"module_categories_by_id", baseURL + "/module_categories/" + testModuleCategoryID},
			{"profiles", baseURL + "/profiles"},
			// {"profiles_by_id", baseURL + "/profiles/" + testProfileID},
			{"skills", baseURL + "/skills"},
			{"skills_by_id", baseURL + "/skills/" + testSkillID},
			{"domains", baseURL + "/domains"},
			{"domains_by_id", baseURL + "/domains/" + testDomainID},
			{"modules", baseURL + "/modules"},
			{"modules_by_id", baseURL + "/modules/" + testModuleID},
			{"objects", baseURL + "/objects"},
			{"objects_by_id", baseURL + "/objects/" + testObjectID},
			{"dictionary", baseURL + "/dictionary"},
			{"data_types", baseURL + "/data_types"},
			{"skill_graph", baseURL + "/skill/graph/" + testSkillID},
			{"domain_graph", baseURL + "/domain/graph/" + testDomainID},
			{"module_graph", baseURL + "/module/graph/" + testModuleID},
			{"object_graph", baseURL + "/object/graph/" + testObjectID},

			// API endpoints
			{"api_version", baseURL + "/api/version"},
			{"api_versions", baseURL + "/api/versions"},
			{"api_profiles", baseURL + "/api/profiles"},
			// {"api_profiles_by_id", baseURL + "/api/profiles/" + testProfileID},
			{"api_extensions", baseURL + "/api/extensions"},
			// Categories API group
			{"api_module_categories", baseURL + "/api/module_categories"},
			{"api_module_categories_by_name", baseURL + "/api/module_categories?name=" + testModuleCategoryID},
			{"api_skill_categories", baseURL + "/api/skill_categories"},
			{"api_skill_categories_by_name", baseURL + "/api/skill_categories?name=" + testSkillCategoryID},
			{"api_domain_categories", baseURL + "/api/domain_categories"},
			{"api_domain_categories_by_name", baseURL + "/api/domain_categories?name=" + testDomainCategoryID},
			// Classes and Objects API group
			{"api_modules", baseURL + "/api/modules"},
			{"api_modules_by_id", baseURL + "/api/modules/" + testModuleID},
			{"api_skills", baseURL + "/api/skills"},
			{"api_skills_by_id", baseURL + "/api/skills/" + testSkillID},
			{"api_domains", baseURL + "/api/domains"},
			{"api_domains_by_id", baseURL + "/api/domains/" + testDomainID},
			{"api_objects", baseURL + "/api/objects"},
			{"api_objects_by_id", baseURL + "/api/objects/" + testObjectID},
			{"api_dictionary", baseURL + "/api/dictionary"},
			{"api_data_types", baseURL + "/api/data_types"},

			// Schema endpoints
			{"schema_skills_by_id", baseURL + "/schema/skills/" + testSkillID},
			{"schema_domains_by_id", baseURL + "/schema/domains/" + testDomainID},
			{"schema_modules_by_id", baseURL + "/schema/modules/" + testModuleID},
			{"schema_objects_by_id", baseURL + "/schema/objects/" + testObjectID},

			// Export endpoints
			{"export_skills", baseURL + "/export/skills"},
			{"export_domains", baseURL + "/export/domains"},
			{"export_modules", baseURL + "/export/modules"},
			{"export_objects", baseURL + "/export/objects"},
			{"export_schema", baseURL + "/export/schema"},

			// Sample endpoints
			{"sample_skills_by_id", baseURL + "/sample/skills/" + testSkillID},
			{"sample_domains_by_id", baseURL + "/sample/domains/" + testDomainID},
			{"sample_modules_by_id", baseURL + "/sample/modules/" + testModuleID},
			{"sample_objects_by_id", baseURL + "/sample/objects/" + testObjectID},
		}

		for _, endpoint := range getEndpoints {
			endpoint := endpoint
			It("should return OK for GET "+endpoint.name, func() {
				resp, err := http.Get(endpoint.url)
				Expect(err).NotTo(HaveOccurred(), "Failed to GET %s", endpoint.name)
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(BeNumerically(">=", 200), "Unexpected status code for %s: %d", endpoint.name, resp.StatusCode)
				Expect(resp.StatusCode).To(BeNumerically("<", 400), "Unexpected status code for %s: %d", endpoint.name, resp.StatusCode)
			})
		}
	})

	Describe("POST Endpoints Health Check", func() {
		// Test IDs to use for parameterized endpoints
		testObjectID := "record"

		// Minimal valid JSON payloads for POST endpoints
		emptyJSON := []byte(`{}`)
		skillJSON := []byte(`{"name": "test_skill"}`)
		domainJSON := []byte(`{"name": "test_domain"}`)
		moduleJSON := []byte(`{"name": "test_module"}`)
		objectJSON := []byte(`{"name": "test_object"}`)

		postEndpoints := []struct {
			name    string
			url     string
			payload []byte
		}{
			{"api_translate_skill", baseURL + "/api/translate/skill", skillJSON},
			{"api_validate_skill", baseURL + "/api/validate/skill", skillJSON},
			{"api_validate_bundle_skill", baseURL + "/api/validate_bundle/skill", emptyJSON},
			{"api_translate_domain", baseURL + "/api/translate/domain", domainJSON},
			{"api_validate_domain", baseURL + "/api/validate/domain", domainJSON},
			{"api_validate_bundle_domain", baseURL + "/api/validate_bundle/domain", emptyJSON},
			{"api_translate_module", baseURL + "/api/translate/module", moduleJSON},
			{"api_validate_module", baseURL + "/api/validate/module", moduleJSON},
			{"api_validate_bundle_module", baseURL + "/api/validate_bundle/module", emptyJSON},
			{"api_translate_object", baseURL + "/api/translate/object/" + testObjectID, objectJSON},
			{"api_validate_object", baseURL + "/api/validate/object/" + testObjectID, objectJSON},
		}

		for _, endpoint := range postEndpoints {
			endpoint := endpoint
			It("should return OK for POST "+endpoint.name, func() {
				req, err := http.NewRequest("POST", endpoint.url, bytes.NewReader(endpoint.payload))
				Expect(err).NotTo(HaveOccurred(), "Failed to create POST request for %s", endpoint.name)
				req.Header.Set("Content-Type", "application/json")
				resp, err := http.DefaultClient.Do(req)
				Expect(err).NotTo(HaveOccurred(), "Failed to POST to %s", endpoint.name)
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(BeNumerically(">=", 200), "Unexpected status code for %s: %d", endpoint.name, resp.StatusCode)
				Expect(resp.StatusCode).To(BeNumerically("<", 500), "Unexpected status code for %s: %d", endpoint.name, resp.StatusCode)
			})
		}
	})

	Describe("404 Not Found Tests", func() {
		// Non-existent ID used for all tests
		nonExistentID := "non_existent_id_12345"

		Describe("GET endpoints with non-existent category names", func() {
			// Browser-facing endpoints (these return 404 when category is not found)
			browserEndpoints := []struct {
				name string
				url  string
			}{
				{"skill_categories_by_name", baseURL + "/skill_categories/" + nonExistentID},
				{"domain_categories_by_name", baseURL + "/domain_categories/" + nonExistentID},
				{"module_categories_by_name", baseURL + "/module_categories/" + nonExistentID},
			}

			for _, endpoint := range browserEndpoints {
				endpoint := endpoint
				It("should return 404 for GET "+endpoint.name+" with non-existent category", func() {
					resp, err := http.Get(endpoint.url)
					Expect(err).NotTo(HaveOccurred(), "Failed to GET %s", endpoint.name)
					defer resp.Body.Close()
					Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "Expected 404 for non-existent category %s, got %d", endpoint.name, resp.StatusCode)
				})
			}

			// API category endpoints - should return 404 when parent is not found
			apiCategoryEndpoints := []struct {
				name string
				url  string
			}{
				{"api_module_categories_by_id", baseURL + "/api/module_categories?id=99999"},
				{"api_module_categories_by_name", baseURL + "/api/module_categories?name=" + nonExistentID},
				{"api_skill_categories_by_id", baseURL + "/api/skill_categories?id=99999"},
				{"api_skill_categories_by_name", baseURL + "/api/skill_categories?name=" + nonExistentID},
				{"api_domain_categories_by_id", baseURL + "/api/domain_categories?id=99999"},
				{"api_domain_categories_by_name", baseURL + "/api/domain_categories?name=" + nonExistentID},
			}

			for _, endpoint := range apiCategoryEndpoints {
				endpoint := endpoint
				It("should return 404 for GET "+endpoint.name+" with non-existent category", func() {
					resp, err := http.Get(endpoint.url)
					Expect(err).NotTo(HaveOccurred(), "Failed to GET %s", endpoint.name)
					defer resp.Body.Close()
					Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "Expected 404 for non-existent category %s, got %d", endpoint.name, resp.StatusCode)

					respBytes, err := io.ReadAll(resp.Body)
					Expect(err).NotTo(HaveOccurred(), "Failed to read response body")
					var errorResp map[string]interface{}
					Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed(), "Response is not valid JSON")
					Expect(errorResp).To(HaveKey("error"), "Error response should contain 'error' field")
				})
			}

			// API class endpoints - should return 404 when class is not found
			apiClassEndpoints := []struct {
				name string
				url  string
			}{
				{"api_modules_by_id", baseURL + "/api/modules/" + nonExistentID},
				{"api_skills_by_id", baseURL + "/api/skills/" + nonExistentID},
				{"api_domains_by_id", baseURL + "/api/domains/" + nonExistentID},
			}

			for _, endpoint := range apiClassEndpoints {
				endpoint := endpoint
				It("should return 404 for GET "+endpoint.name+" with non-existent class", func() {
					resp, err := http.Get(endpoint.url)
					Expect(err).NotTo(HaveOccurred(), "Failed to GET %s", endpoint.name)
					defer resp.Body.Close()
					Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "Expected 404 for non-existent class %s, got %d", endpoint.name, resp.StatusCode)
				})
			}
		})

		Describe("GET endpoints with non-existent class names", func() {
			classEndpoints := []struct {
				name string
				url  string
			}{
				{"skills_by_id", baseURL + "/skills/" + nonExistentID},
				{"domains_by_id", baseURL + "/domains/" + nonExistentID},
				{"modules_by_id", baseURL + "/modules/" + nonExistentID},
				{"objects_by_id", baseURL + "/objects/" + nonExistentID},
				{"skill_graph", baseURL + "/skill/graph/" + nonExistentID},
				{"domain_graph", baseURL + "/domain/graph/" + nonExistentID},
				{"module_graph", baseURL + "/module/graph/" + nonExistentID},
				{"object_graph", baseURL + "/object/graph/" + nonExistentID},
				{"api_objects_by_id", baseURL + "/api/objects/" + nonExistentID},
				{"api_modules_by_id", baseURL + "/api/modules/" + nonExistentID},
				{"api_skills_by_id", baseURL + "/api/skills/" + nonExistentID},
				{"api_domains_by_id", baseURL + "/api/domains/" + nonExistentID},
				{"schema_skills_by_id", baseURL + "/schema/skills/" + nonExistentID},
				{"schema_domains_by_id", baseURL + "/schema/domains/" + nonExistentID},
				{"schema_modules_by_id", baseURL + "/schema/modules/" + nonExistentID},
				{"schema_objects_by_id", baseURL + "/schema/objects/" + nonExistentID},
				{"sample_skills_by_id", baseURL + "/sample/skills/" + nonExistentID},
				{"sample_domains_by_id", baseURL + "/sample/domains/" + nonExistentID},
				{"sample_modules_by_id", baseURL + "/sample/modules/" + nonExistentID},
				{"sample_objects_by_id", baseURL + "/sample/objects/" + nonExistentID},
			}

			for _, endpoint := range classEndpoints {
				endpoint := endpoint
				It("should return 404 for GET "+endpoint.name+" with non-existent class", func() {
					resp, err := http.Get(endpoint.url)
					Expect(err).NotTo(HaveOccurred(), "Failed to GET %s", endpoint.name)
					defer resp.Body.Close()
					Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "Expected 404 for non-existent class %s, got %d", endpoint.name, resp.StatusCode)
				})
			}
		})

	})

	Describe("POST Endpoints with Non-Existent IDs (should return 200)", func() {
		// Non-existent ID used for all tests
		nonExistentID := "non_existent_id_12345"
		objectJSON := []byte(`{"name": "test_object"}`)

		postEndpoints := []struct {
			name    string
			url     string
			payload []byte
		}{
			{"api_translate_object", baseURL + "/api/translate/object/" + nonExistentID, objectJSON},
			{"api_validate_object", baseURL + "/api/validate/object/" + nonExistentID, objectJSON},
		}

		for _, endpoint := range postEndpoints {
			endpoint := endpoint
			It("should return 200 for POST "+endpoint.name+" with non-existent object ID", func() {
				req, err := http.NewRequest("POST", endpoint.url, bytes.NewReader(endpoint.payload))
				Expect(err).NotTo(HaveOccurred(), "Failed to create POST request for %s", endpoint.name)
				req.Header.Set("Content-Type", "application/json")
				resp, err := http.DefaultClient.Do(req)
				Expect(err).NotTo(HaveOccurred(), "Failed to POST to %s", endpoint.name)
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK), "Expected 200 for %s with non-existent object ID, got %d", endpoint.name, resp.StatusCode)
			})
		}
	})

	Describe("Categories API - id and name parameter validation", func() {
		It("should return 400 when both id and name are provided but refer to different nodes", func() {
			// Test with module_categories endpoint - use a valid ID and a different valid name
			resp, err := http.Get(baseURL + "/api/module_categories?id=1&name=prompt")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with mismatched id and name")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(http.StatusBadRequest), "Expected 400 for mismatched id and name, got %d", resp.StatusCode)

			respBytes, err := io.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred(), "Failed to read response body")
			var errorResp map[string]interface{}
			Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed(), "Response is not valid JSON")
			Expect(errorResp).To(HaveKey("error"), "Error response should contain 'error' field")
		})

		It("should return 200 when both id and name are provided and refer to the same node", func() {
			// Test with module_categories endpoint - use id=1 (core) and name=core
			// Note: This assumes id 1 corresponds to name "core"
			resp, err := http.Get(baseURL + "/api/module_categories?id=1&name=core")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with matching id and name")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(BeNumerically(">=", 200), "Expected 200+ for matching id and name, got %d", resp.StatusCode)
			Expect(resp.StatusCode).To(BeNumerically("<", 400), "Expected <400 for matching id and name, got %d", resp.StatusCode)
		})

		It("should return 400 when id is invalid (non-numeric)", func() {
			resp, err := http.Get(baseURL + "/api/module_categories?id=invalid&name=core")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with invalid id")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(http.StatusBadRequest), "Expected 400 for invalid id, got %d", resp.StatusCode)
		})

		It("should return 400 when id doesn't exist", func() {
			resp, err := http.Get(baseURL + "/api/module_categories?id=99999&name=core")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with non-existent id")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(http.StatusBadRequest), "Expected 400 for non-existent id, got %d", resp.StatusCode)
		})

		It("should return 400 when name doesn't exist", func() {
			resp, err := http.Get(baseURL + "/api/module_categories?id=1&name=nonexistent_name_12345")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with non-existent name")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(http.StatusBadRequest), "Expected 400 for non-existent name, got %d", resp.StatusCode)
		})

		It("should work with only id parameter", func() {
			resp, err := http.Get(baseURL + "/api/module_categories?id=1")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with only id")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(BeNumerically(">=", 200), "Expected 200+ for id-only request, got %d", resp.StatusCode)
			Expect(resp.StatusCode).To(BeNumerically("<", 400), "Expected <400 for id-only request, got %d", resp.StatusCode)
		})

		It("should work with only name parameter", func() {
			resp, err := http.Get(baseURL + "/api/module_categories?name=core")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with only name")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(BeNumerically(">=", 200), "Expected 200+ for name-only request, got %d", resp.StatusCode)
			Expect(resp.StatusCode).To(BeNumerically("<", 400), "Expected <400 for name-only request, got %d", resp.StatusCode)
		})

		It("should work with hierarchical name format", func() {
			resp, err := http.Get(baseURL + "/api/module_categories?name=core/language_model")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with hierarchical name")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(BeNumerically(">=", 200), "Expected 200+ for hierarchical name, got %d", resp.StatusCode)
			Expect(resp.StatusCode).To(BeNumerically("<", 400), "Expected <400 for hierarchical name, got %d", resp.StatusCode)
		})

		It("should work with simple name format (last segment)", func() {
			resp, err := http.Get(baseURL + "/api/module_categories?name=prompt")
			Expect(err).NotTo(HaveOccurred(), "Failed to GET /api/module_categories with simple name")
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(BeNumerically(">=", 200), "Expected 200+ for simple name, got %d", resp.StatusCode)
			Expect(resp.StatusCode).To(BeNumerically("<", 400), "Expected <400 for simple name, got %d", resp.StatusCode)
		})
	})
})
