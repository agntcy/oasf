import fs from 'fs/promises';
import convert from 'json-schema-to-openapi-schema';
import yaml from 'js-yaml';

const inputPath = process.env.INPUT_SCHEMA;
const outputPath = process.env.OUTPUT_FILE;

if (!inputPath || !outputPath) {
  console.error('Missing required env vars: INPUT_SCHEMA and OUTPUT_FILE');
  console.error('Example usage: INPUT_SCHEMA=src/user.schema.json OUTPUT_FILE=gen/openapi/user.yaml node convert-json-to-openapi.js');
  process.exit(1);
}

function cleanJsonSchema(schema) {
  if (Array.isArray(schema)) {
    return schema.map(cleanJsonSchema);
  }

  if (schema && typeof schema === 'object') {
    const cleaned = {};

    for (const [key, value] of Object.entries(schema)) {
      if (key === '$id' || key === '$schema' || key === 'const' || key === 'title' || key === 'required' || key === 'enum') {
        continue;
      }

      if (key === '$ref' && typeof value === 'string' && value.startsWith('#/$defs/')) {
        cleaned[key] = value.replace('#/$defs/', '#/components/schemas/');
        continue;
      }

      cleaned[key] = cleanJsonSchema(value);
    }

    return cleaned;
  }

  return schema;
}

async function main() {
  try {
    const fileContent = await fs.readFile(inputPath, 'utf-8');
    const jsonSchema = JSON.parse(fileContent);
    const openapiSchema = await convert(jsonSchema, { cloneSchema: 'deep' });

    const componentsSchemas = {};

    // Move $defs to components.schemas
    if (openapiSchema.$defs) {
      for (const [key, def] of Object.entries(openapiSchema.$defs)) {
        componentsSchemas[key] = def;
      }
      delete openapiSchema.$defs;
    }

    // Add main schema (use filename as key or default to 'RootSchema')
    const baseName = inputPath.split('/').pop().replace(/\..*$/, '');
    componentsSchemas[baseName || 'RootSchema'] = openapiSchema;

    const fixedSchemas = cleanJsonSchema(componentsSchemas);

    const openapiDoc = {
      openapi: '3.0.3',
      info: {
        title: 'Generated OpenAPI Spec',
        version: '1.0.0',
        description: baseName,
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT',
        },
      },
      paths: {},
      components: {
        schemas: fixedSchemas,
      },
    };

    const yamlOutput = yaml.dump(openapiDoc, { noRefs: true, lineWidth: -1 });

    await fs.mkdir(outputPath.split('/').slice(0, -1).join('/'), { recursive: true });
    await fs.writeFile(outputPath, yamlOutput, 'utf-8');

    console.log(`OpenAPI 3.0.3 YAML written to: ${outputPath}`);
  } catch (err) {
    console.error('Failed to generate OpenAPI YAML:', err);
    process.exit(1);
  }
}

main();
