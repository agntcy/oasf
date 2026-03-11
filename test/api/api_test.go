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
		apiEndpoint:        baseURL + "/api/objects?name=record",
		schemaEndpoint:     baseURL + "/schema/objects/record",
		sampleEndpoint:     baseURL + "/sample/objects/record",
		validationEndpoint: baseURL + "/api/validate/object/record",
	},
	{
		entityType:         "objects",
		fileName:           "locator.json",
		apiEndpoint:        baseURL + "/api/objects?name=locator",
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
		// Test names to use for parameterized endpoints
		testSkillName := "contextual_comprehension"
		testDomainName := "internet_of_things"
		testModuleName := "observability"
		testSkillCategoryName := "natural_language_processing"
		testDomainCategoryName := "healthcare"
		testModuleCategoryName := "core"
		testObjectName := "record"
		// testProfileName := "default" // Uncomment and set to a valid profile name if available

		getEndpoints := []struct {
			name string
			url  string
		}{
			// Root and category pages
			{"root", baseURL + "/"},
			{"skill_categories", baseURL + "/skill_categories"},
			{"skill_categories_by_name", baseURL + "/skill_categories/" + testSkillCategoryName},
			{"domain_categories", baseURL + "/domain_categories"},
			{"domain_categories_by_name", baseURL + "/domain_categories/" + testDomainCategoryName},
			{"module_categories", baseURL + "/module_categories"},
			{"module_categories_by_name", baseURL + "/module_categories/" + testModuleCategoryName},
			{"profiles", baseURL + "/profiles"},
			// {"profiles_by_name", baseURL + "/profiles/" + testProfileName},
			{"skills", baseURL + "/skills"},
			{"skills_by_name", baseURL + "/skills/" + testSkillName},
			{"domains", baseURL + "/domains"},
			{"domains_by_name", baseURL + "/domains/" + testDomainName},
			{"modules", baseURL + "/modules"},
			{"modules_by_name", baseURL + "/modules/" + testModuleName},
			{"objects", baseURL + "/objects"},
			{"objects_by_name", baseURL + "/objects/" + testObjectName},
			{"dictionary", baseURL + "/dictionary"},
			{"data_types", baseURL + "/data_types"},
			{"skill_graph", baseURL + "/skill/graph/" + testSkillName},
			{"domain_graph", baseURL + "/domain/graph/" + testDomainName},
			{"module_graph", baseURL + "/module/graph/" + testModuleName},
			{"object_graph", baseURL + "/object/graph/" + testObjectName},

			// API endpoints
			{"api_version", baseURL + "/api/version"},
			{"api_versions", baseURL + "/api/versions"},
			{"api_profiles", baseURL + "/api/profiles"},
			{"api_extensions", baseURL + "/api/extensions"},
			{"api_schema", baseURL + "/api/schema"},
			// Categories API group
			{"api_module_categories", baseURL + "/api/module_categories"},
			{"api_module_categories_by_name", baseURL + "/api/module_categories?name=" + testModuleCategoryName},
			{"api_skill_categories", baseURL + "/api/skill_categories"},
			{"api_skill_categories_by_name", baseURL + "/api/skill_categories?name=" + testSkillCategoryName},
			{"api_domain_categories", baseURL + "/api/domain_categories"},
			{"api_domain_categories_by_name", baseURL + "/api/domain_categories?name=" + testDomainCategoryName},
			// Classes and Objects API group
			{"api_modules", baseURL + "/api/modules"},
			{"api_modules_by_name", baseURL + "/api/modules?name=" + testModuleName},
			{"api_skills", baseURL + "/api/skills"},
			{"api_skills_by_name", baseURL + "/api/skills?name=" + testSkillName},
			{"api_domains", baseURL + "/api/domains"},
			{"api_domains_by_name", baseURL + "/api/domains?name=" + testDomainName},
			{"api_objects", baseURL + "/api/objects"},
			{"api_objects_by_name", baseURL + "/api/objects?name=" + testObjectName},
			{"api_dictionary", baseURL + "/api/dictionary"},
			{"api_data_types", baseURL + "/api/data_types"},

			// Schema endpoints
			{"schema_skills_by_name", baseURL + "/schema/skills/" + testSkillName},
			{"schema_domains_by_name", baseURL + "/schema/domains/" + testDomainName},
			{"schema_modules_by_name", baseURL + "/schema/modules/" + testModuleName},
			{"schema_objects_by_name", baseURL + "/schema/objects/" + testObjectName},

			// Sample endpoints
			{"sample_skills_by_name", baseURL + "/sample/skills/" + testSkillName},
			{"sample_domains_by_name", baseURL + "/sample/domains/" + testDomainName},
			{"sample_modules_by_name", baseURL + "/sample/modules/" + testModuleName},
			{"sample_objects_by_name", baseURL + "/sample/objects/" + testObjectName},
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
		// Test names to use for parameterized endpoints
		testObjectName := "record"

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
			{"api_translate_object", baseURL + "/api/translate/object/" + testObjectName, objectJSON},
			{"api_validate_object", baseURL + "/api/validate/object/" + testObjectName, objectJSON},
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
		// Non-existent name used for all tests
		nonExistentName := "non_existent_name_12345"

		Describe("GET endpoints with non-existent category names", func() {
			// Browser-facing endpoints (these return 404 when category is not found)
			browserEndpoints := []struct {
				name string
				url  string
			}{
				{"skill_categories_by_name", baseURL + "/skill_categories/" + nonExistentName},
				{"domain_categories_by_name", baseURL + "/domain_categories/" + nonExistentName},
				{"module_categories_by_name", baseURL + "/module_categories/" + nonExistentName},
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
				{"api_module_categories_by_name", baseURL + "/api/module_categories?name=" + nonExistentName},
				{"api_skill_categories_by_id", baseURL + "/api/skill_categories?id=99999"},
				{"api_skill_categories_by_name", baseURL + "/api/skill_categories?name=" + nonExistentName},
				{"api_domain_categories_by_id", baseURL + "/api/domain_categories?id=99999"},
				{"api_domain_categories_by_name", baseURL + "/api/domain_categories?name=" + nonExistentName},
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
				{"api_modules_by_name", baseURL + "/api/modules?name=" + nonExistentName},
				{"api_skills_by_name", baseURL + "/api/skills?name=" + nonExistentName},
				{"api_domains_by_name", baseURL + "/api/domains?name=" + nonExistentName},
				{"api_modules_by_id", baseURL + "/api/modules?id=99999"},
				{"api_skills_by_id", baseURL + "/api/skills?id=99999"},
				{"api_domains_by_id", baseURL + "/api/domains?id=99999"},
			}

			for _, endpoint := range apiClassEndpoints {
				endpoint := endpoint
				It("should return 404 for GET "+endpoint.name+" with non-existent class", func() {
					resp, err := http.Get(endpoint.url)
					Expect(err).NotTo(HaveOccurred(), "Failed to GET %s", endpoint.name)
					defer resp.Body.Close()
					Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "Expected 404 for non-existent class %s, got %d", endpoint.name, resp.StatusCode)

					respBytes, err := io.ReadAll(resp.Body)
					Expect(err).NotTo(HaveOccurred(), "Failed to read response body")
					var errorResp map[string]interface{}
					Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed(), "Response is not valid JSON")
					Expect(errorResp).To(HaveKey("error"), "Error response should contain 'error' field")
				})
			}
		})

		Describe("GET endpoints with non-existent class names", func() {
			classEndpoints := []struct {
				name string
				url  string
			}{
				{"skills_by_name", baseURL + "/skills/" + nonExistentName},
				{"domains_by_name", baseURL + "/domains/" + nonExistentName},
				{"modules_by_name", baseURL + "/modules/" + nonExistentName},
				{"objects_by_name", baseURL + "/objects/" + nonExistentName},
				{"skill_graph", baseURL + "/skill/graph/" + nonExistentName},
				{"domain_graph", baseURL + "/domain/graph/" + nonExistentName},
				{"module_graph", baseURL + "/module/graph/" + nonExistentName},
				{"object_graph", baseURL + "/object/graph/" + nonExistentName},
				{"api_objects_by_name", baseURL + "/api/objects?name=" + nonExistentName},
				{"schema_skills_by_name", baseURL + "/schema/skills/" + nonExistentName},
				{"schema_domains_by_name", baseURL + "/schema/domains/" + nonExistentName},
				{"schema_modules_by_name", baseURL + "/schema/modules/" + nonExistentName},
				{"schema_objects_by_name", baseURL + "/schema/objects/" + nonExistentName},
				{"sample_skills_by_name", baseURL + "/sample/skills/" + nonExistentName},
				{"sample_domains_by_name", baseURL + "/sample/domains/" + nonExistentName},
				{"sample_modules_by_name", baseURL + "/sample/modules/" + nonExistentName},
				{"sample_objects_by_name", baseURL + "/sample/objects/" + nonExistentName},
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

	Describe("POST Endpoints with Non-Existent Names (should return 200)", func() {
		// Non-existent name used for all tests
		nonExistentName := "non_existent_name_12345"
		objectJSON := []byte(`{"name": "test_object"}`)

		postEndpoints := []struct {
			name    string
			url     string
			payload []byte
		}{
			{"api_translate_object", baseURL + "/api/translate/object/" + nonExistentName, objectJSON},
			{"api_validate_object", baseURL + "/api/validate/object/" + nonExistentName, objectJSON},
		}

		for _, endpoint := range postEndpoints {
			endpoint := endpoint
			It("should return 200 for POST "+endpoint.name+" with non-existent object name", func() {
				req, err := http.NewRequest("POST", endpoint.url, bytes.NewReader(endpoint.payload))
				Expect(err).NotTo(HaveOccurred(), "Failed to create POST request for %s", endpoint.name)
				req.Header.Set("Content-Type", "application/json")
				resp, err := http.DefaultClient.Do(req)
				Expect(err).NotTo(HaveOccurred(), "Failed to POST to %s", endpoint.name)
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK), "Expected 200 for %s with non-existent object name, got %d", endpoint.name, resp.StatusCode)
			})
		}
	})

	Describe("POST Endpoints with Invalid Body (should return 400)", func() {
		invalidBody := []byte(`"just a string"`)

		translateEndpoints := []struct {
			name string
			url  string
		}{
			{"api_translate_skill", baseURL + "/api/translate/skill"},
			{"api_translate_domain", baseURL + "/api/translate/domain"},
			{"api_translate_module", baseURL + "/api/translate/module"},
			{"api_translate_object", baseURL + "/api/translate/object/record"},
		}

		for _, endpoint := range translateEndpoints {
			endpoint := endpoint
			It("should return 400 for POST "+endpoint.name+" with non-object body", func() {
				req, err := http.NewRequest("POST", endpoint.url, bytes.NewReader(invalidBody))
				Expect(err).NotTo(HaveOccurred())
				req.Header.Set("Content-Type", "application/json")
				resp, err := http.DefaultClient.Do(req)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusBadRequest))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})
		}

		validateEndpoints := []struct {
			name string
			url  string
		}{
			{"api_validate_skill", baseURL + "/api/validate/skill"},
			{"api_validate_domain", baseURL + "/api/validate/domain"},
			{"api_validate_module", baseURL + "/api/validate/module"},
			{"api_validate_object", baseURL + "/api/validate/object/record"},
		}

		for _, endpoint := range validateEndpoints {
			endpoint := endpoint
			It("should return 400 for POST "+endpoint.name+" with non-object body", func() {
				req, err := http.NewRequest("POST", endpoint.url, bytes.NewReader(invalidBody))
				Expect(err).NotTo(HaveOccurred())
				req.Header.Set("Content-Type", "application/json")
				resp, err := http.DefaultClient.Do(req)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusBadRequest))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})
		}
	})

	Describe("Classes API - id and name parameter validation", func() {
		classEndpoints := []struct {
			family          string
			path            string
			validName       string
			validID         string
			mismatchID      string
			hierarchicalName string
		}{
			{"skills", "/api/skills", "contextual_comprehension", "10101", "601", "analytical_skills/mathematical_reasoning"},
			{"domains", "/api/domains", "internet_of_things", "101", "2005", "agriculture/precision_agriculture"},
			{"modules", "/api/modules", "observability", "101", "103", "core/language_model/prompt"},
		}

		for _, ep := range classEndpoints {
			ep := ep

			It("should return 200 for "+ep.family+" when name is provided", func() {
				resp, err := http.Get(baseURL + ep.path + "?name=" + ep.validName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 200 for "+ep.family+" when id is provided", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=" + ep.validID)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 200 for "+ep.family+" when both matching id and name are provided", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=" + ep.validID + "&name=" + ep.validName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 200 for "+ep.family+" with hierarchical name", func() {
				resp, err := http.Get(baseURL + ep.path + "?name=" + ep.hierarchicalName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 400 for "+ep.family+" when id is invalid (non-numeric)", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=invalid")
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusBadRequest))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})

			It("should return 400 for "+ep.family+" when id and name refer to different classes", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=" + ep.mismatchID + "&name=" + ep.validName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusBadRequest))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})

			It("should return 404 for "+ep.family+" when name does not exist", func() {
				resp, err := http.Get(baseURL + ep.path + "?name=nonexistent_12345")
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusNotFound))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})

			It("should return 404 for "+ep.family+" when id does not exist", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=99999")
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusNotFound))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})
		}
	})

	Describe("Objects API - name parameter validation", func() {
		It("should return 200 for objects when name is provided", func() {
			resp, err := http.Get(baseURL + "/api/objects?name=record")
			Expect(err).NotTo(HaveOccurred())
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(http.StatusOK))
		})

		It("should return 404 for objects when name does not exist", func() {
			resp, err := http.Get(baseURL + "/api/objects?name=nonexistent_12345")
			Expect(err).NotTo(HaveOccurred())
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(http.StatusNotFound))

			respBytes, err := io.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			var errorResp map[string]interface{}
			Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
			Expect(errorResp).To(HaveKey("error"))
		})
	})

	Describe("Categories API - id and name parameter validation", func() {
		categoryEndpoints := []struct {
			family     string
			path       string
			validName  string
			validID    string
			mismatchID string
			hierName   string
			simpleName string
		}{
			{"module_categories", "/api/module_categories", "core", "1", "2", "core/language_model", "prompt"},
			{"skill_categories", "/api/skill_categories", "analytical_skills", "5", "1", "natural_language_processing/personalization", "personalization"},
			{"domain_categories", "/api/domain_categories", "agriculture", "11", "1", "healthcare/telemedicine", "telemedicine"},
		}

		for _, ep := range categoryEndpoints {
			ep := ep

			It("should return 200 for "+ep.family+" when name is provided", func() {
				resp, err := http.Get(baseURL + ep.path + "?name=" + ep.validName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 200 for "+ep.family+" when id is provided", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=" + ep.validID)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 200 for "+ep.family+" when matching id and name are provided", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=" + ep.validID + "&name=" + ep.validName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 200 for "+ep.family+" with hierarchical name", func() {
				resp, err := http.Get(baseURL + ep.path + "?name=" + ep.hierName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 200 for "+ep.family+" with simple name (last segment)", func() {
				resp, err := http.Get(baseURL + ep.path + "?name=" + ep.simpleName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusOK))
			})

			It("should return 400 for "+ep.family+" when id is invalid (non-numeric)", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=invalid")
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusBadRequest))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})

			It("should return 400 for "+ep.family+" when id and name refer to different nodes", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=" + ep.mismatchID + "&name=" + ep.validName)
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusBadRequest))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})

			It("should return 404 for "+ep.family+" when name does not exist", func() {
				resp, err := http.Get(baseURL + ep.path + "?name=nonexistent_12345")
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusNotFound))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})

			It("should return 404 for "+ep.family+" when id does not exist", func() {
				resp, err := http.Get(baseURL + ep.path + "?id=99999")
				Expect(err).NotTo(HaveOccurred())
				defer resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(http.StatusNotFound))

				respBytes, err := io.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				var errorResp map[string]interface{}
				Expect(json.Unmarshal(respBytes, &errorResp)).To(Succeed())
				Expect(errorResp).To(HaveKey("error"))
			})
		}
	})

	Describe("Schema API - response content", func() {
		It("should return valid JSON with expected top-level keys from /api/schema", func() {
			resp, err := http.Get(baseURL + "/api/schema")
			Expect(err).NotTo(HaveOccurred())
			defer resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(http.StatusOK))

			respBytes, err := io.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())

			var schemaResp map[string]interface{}
			Expect(json.Unmarshal(respBytes, &schemaResp)).To(Succeed(), "/api/schema response is not valid JSON")
			Expect(len(schemaResp)).To(BeNumerically(">", 0), "/api/schema response should not be empty")
		})
	})
})
