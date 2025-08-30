# How to Contribute

Thanks for your interest in contributing to Open Agentic Schema Framework!
Here are a few general guidelines on contributing and reporting bugs that we ask
you to review. Following these guidelines helps to communicate that you respect
the time of the contributors managing and developing this open source project.
In return, they should reciprocate that respect in addressing your issue,
assessing changes, and helping you finalize your pull requests. In that spirit
of mutual respect, we endeavor to review incoming issues and pull requests
within 10 days, and will close any lingering issues or pull requests after 60
days of inactivity.

Please note that all of your interactions in the project are subject to our
[Code of Conduct](/CODE_OF_CONDUCT.md). This includes creation of issues or pull
requests, commenting on issues or pull requests, and extends to all interactions
in any real-time space for example, Slack, Discord, and others.

# OASF Contribution Guide

This documentation presents guidelines and expected etiquette to successfully
contribute to the development of OASF Schemas and the framework itself.

---

### Key OASF Terminology

1. **Field**: A field is a unique identifier name for a piece of data contained in OASF. Each field also designates a corresponding data_type.
2. **Object**: An object is a collection of contextually related fields and other objects. It is also a data_type in OASF.
3. **Class**: A class is a particular set of attributes (including fields & objects) representing metadata associated to an OASF record. It is also a data_type in OASF.
4. **Class Family**: Classes are currently grouped into 3 families: skills, domains, and features.
5. **Attribute**: An attribute is the more generic name for both fields and objects/classes in OASF. A field is a scalar attribute while an object/class is a complex attribute.
6. **Category:** A Category organizes classes that represent a particular domain.

## How do I add to the schema?

### Adding/Modifying a `class`

1. Determine where in the taxonomy of the class family you would want to add the new `class`.
2. Create a new file → `<class_name.json>` inside the family and category specific subdirectory in the [/schema](https://github.com/agntcy/oasf/tree/main/schema) folder. Template available [here](https://github.com/agntcy/oasf/blob/main/schema/templates/class_name.json).
3. Define the `class` itself.
4. In case of a `feature` class, make sure to overwrite the `data` attribute with a new object containing all the
   feature-specific attributes → [How to define an `object`](#how-to-define-an-object).
5. Finally, verify the changes are working as expected in your local [oasf/server](https://github.com/agntcy/oasf/tree/main/server).

---

### Adding/Modifying an `attribute`

1. All the available `attributes` - `fields` & `objects` in OASF are and will need to be defined in the attribute dictionary, the [dictionary.json](https://github.com/agntcy/oasf/blob/main/schema/dictionary.json) file and [/objects](https://github.com/agntcy/oasf/tree/main/schema/objects) folder if defining an object.
2. Determine if a new attribute is required for your change, it might already be defined in the attribute dictionary and/or the [/objects](https://github.com/agntcy/oasf/tree/main/schema/objects) folder.
3. Before adding a new attribute, review the following OASF attribute conventions:
   - Attribute names must be a valid UTF-8 sequence.
   - Attribute names must be all lowercase.
   - Combine words using underscore.
   - No special characters except underscore.
   - Use present tense unless the attribute describes historical information.
   - Use singular and plural names properly to reflect the field content.
   - When attribute represents multiple entities, the attribute name should be pluralized and the value type should be an array.
   - Avoid repetition of words.
   - Avoid abbreviations when possible. Some exceptions can be made for well-accepted abbreviation like well known
     acronyms (for example, LLM, AI)

#### How to define a `field` in the dictionary?

To add a new field in OASF, you need to define it in the [dictionary.json](https://github.com/agntcy/oasf/blob/main/schema/dictionary.json) file as described below.

Sample entry in the dictionary:

```
    "name": {
      "caption": "Name",
      "description": "The name of the entity. See specific usage.",
      "type": "string_t"
    }
```

Choose a **unique** field you want to add, `name` in the example above and populate it as described below.

1. `caption` → Add a user-friendly name to the field.
2. `description` → Add concise description to define the attributes.
   1. Note that `field` descriptions can be overridden in the `class/object`, therefore if it’s a common field (like name, label, uid, etc.) feel free to add a generic description, specific descriptions can be added in the `class/object` definition. For example,
   2. A generic definition of `name` in the dictionary:
      1. `name` : `The name of the entity. See specific usage.`
   3. Specific description of `name` in the `record` object:
      1. `name` : `The name of the record. For example: <code>Marketing Strategy Agent</code>.`
3. `type` → Review OASF data_types and ensure you utilize appropriate types while defining new fields.
   1. All the available data_types can be accessed [here](https://schema.oasf.outshift.com/data_types).
   2. They are also accessible in your [local instance of the OASF server](http://localhost:8080/data_types).
4. `is_array` → This a boolean key:value pair that you would need to add if the field you are defining is an array.
   1. e.g. `"is_array": true`

#### How to define an `object`?

1. All the available `objects` need to be defined as individual field entries in the dictionary, the [dictionary.json](https://github.com/agntcy/oasf/blob/main/schema/dictionary.json) file and as distinct `.json` files in the [/objects](https://github.com/agntcy/oasf/tree/main/schema/objects) folder.
2. Review existing Objects, determine if a modification of the existing object would be sufficient or if there’s a need for a completely new object.
3. Use the template available [here](https://github.com/agntcy/oasf/blob/main/schema/templates/object_name.json), to get started with `.json` file definition.

An example `locator.json` object file,

```
{
  "caption": "Record Locator",
  "description": "Locators provide actual artifact locators of the data's record. For example, this can reference sources such as Helm charts, Docker images, binaries, and so on.",
  "extends": "object",
  "name": "locator",
  "attributes": {
    "type": {
      "caption": "Type",
      "description": "Describes the type of the release manifest pointed by its URI. Allowed values MAY be defined for common manifest types.",
      "requirement": "required",
      "enum": {
        "unspecified": {
          "caption": "Unspecified"
        },
        "helm_chart": {
          "caption": "Helm Chart"
        },
        "docker_image": {
          "caption": "Docker Image"
        },
        "python_package": {
          "caption": "Python Package"
        },
        "source_code": {
          "caption": "Source Code"
        },
        "binary": {
          "caption": "Binary"
        }
      }
    },
    "url": {
      "caption": "URL",
      "description": "Specifies an URI from which this object MAY be downloaded. Value MUST conform to RFC 3986. Value SHOULD use the http and https schemes, as defined in RFC 7230.",
      "requirement": "required"
    },
    "annotations": {
      "caption": "Annotations",
      "description": "Additional metadata associated with the record locator.",
      "requirement": "optional"
    },
    "size": {
      "caption": "Size",
      "description": "Specifies the size of the release manifest in bytes.",
      "requirement": "optional"
    },
    "digest": {
      "caption": "Digest",
      "description": "Specifies the digest of the release manifest contents.",
      "requirement": "optional"
    }
  }
}
```

4. `caption` → Add a user-friendly name to the object.
5. `description` → Add a concise description to define the object.
6. `extends` → Ensure the value is `object` or an existing object, e.g. `extension_data` (All objects in OASF must extend a base definition of `object` or another existing object.)
7. `name` → Add a **unique** name of the object. `name` must match the filename of the actual `.json` file.
8. `attributes` → Add the attributes that you want to define in the object,
   1. `requirement` → For each attribute ensure you add a requirement value. Valid values are `optional`, `required`, `recommended`
   2. `$include` → You can include attributes from other places; to do so, specify a virtual attribute called `$include` and give its value as the list of files (relative to the root of the schema repository) that should contribute their attributes to this object. _e.g._
      ```
      "attributes": {
        "$include": [
          "profiles/host.json"
        ],
        ...
      }
      ```
9. `constraints` → For each class you can add constraints on the attribute requirements. Valid constraint types are `at_least_one`, `just_one`. e.g.
   ```
    "constraints": {
       "at_least_one": [
           "id",
           "name"
        ]
   }
   ```

**Note:** If you want to create an object which would act only as a base for other objects (without it being used as an enum object), you must prefix the object `name` and the actual `json` filename with an `_`. The resultant object will not be visible in the [OASF Server](https://schema.oasf.outshift.com/objects).

Sample entry in the `dictionary.json`,

```
    "locators": {
      "caption": "Record Locators",
      "description": "Locators provide actual artifact locators of the data's record. For example, this can reference sources such as helm charts, docker images, binaries, and so on.",
      "type": "locator",
      "is_array": true
    }
```

Choose a **unique** object you want to add, `locators` in the example above and populate it as described below.

1. `caption` → Add a user-friendly name to the object
2. `description` → Add a concise description to define the object.
3. `type` → Add the type of the object you are defining.
4. `is_array` → This a boolean key:value pair that you would need to add if the object you are defining is an array.
   1. e.g. `"is_array": true`
5. `is_enum` → This a boolean key:value pair that you would need to add if the attribute you are defining is a `class/object` and only the entities extending the `class/object` are accepted as a value.
   1. e.g. `"is_enum": true`

---

### Deprecating an attribute

To deprecate an attribute (`field`, `object`) follow the steps below:

1. Create a GitHub issue, explaining why an attribute needs to be deprecated and what the alternate solution is.
2. Utilize the following flag to allow deprecation of attributes. This flag needs to be added a json property of the attribute that is the subject of deprecation.
   ```
         "@deprecated": {
           "message": "Use the <code> ALTERNATE_ATTRIBUTE </code> attribute instead.",
           "since": "semver"
         }
   ```
3. Example of a deprecated field
   ```
   "packages": {
     "@deprecated": {
       "message": "Use the <code> affected_packages </code> attribute instead.",
       "since": "1.0.0"
     },
     "caption": "Software Packages",
     "description": "List of vulnerable packages as identified by the security product",
     "is_array": true,
     "type": "package"
   }
   ```
4. Example of a deprecated object
   ```
    {
      "caption": "Finding",
      "description": "The Finding object describes metadata related to a security finding generated by a security tool or system.",
      "extends": "object",
      "name": "finding",
      "@deprecated": {
        "message": "Use the new <code>finding_info</code> object.",
        "since": "1.0.0"
      },
      "attributes": {...}
    }
   ```

---

### Verifying the changes

Contributors should verify the changes before they submit the PR, the best
method to test and verify their changes is to run a local instance of the
[oasf/server](https://github.com/agntcy/oasf/tree/main/server). Follow the
instructions [here](https://github.com/agntcy/oasf/blob/main/README.md#deploy-locally) to deploy in a local Kind cluster, or [here](https://github.com/agntcy/oasf/blob/main/server/README.md) to set your own local OASF server using Elixir tooling.

If there are any problems with the newly made changes, the server will throw
corresponding errors. Sample error messages:

```
[error] mfa=Schema.Utils.update_attributes/4 line=331  "Record" usesundefined attribute: locators: %{description: "List of source locators where this record can be found or used from.", requirement: "required", caption: "Locators", _source: :record}
[error] mfa=Schema.Utils.update_data_type/3 line=224  Missing data type for: otel_exporters/otel_tls_config, will use string_t type
```

Address the errors before submitting the changes, your server run should be completely error free.

---

## OASF Extensions

The OASF Schema can be extended by adding an extension that defines additional
attributes, objects, profiles, classes, or categories.
Extensions allow one to create vendor/customer specific schemas or augment an
existing schema to better suit their custom requirements. Extensions can also
be used to factor out non-essential schema domains keeping the core schema
succinct. Extensions use the framework in the same way as a new schema,
optionally creating categories, profiles, or classes from the dictionary.

As with categories and classes, extensions have unique IDs within the
framework as well as their own versioning. The following sections provide
guidelines to create extensions within OASF.

### Reserve a UID and Name for your extension

In order to reserve an ID space, and make your extension public, add a unique
identifier & a unique name for your extension in the OASF Extensions Registry
[here](https://github.com/agntcy/oasf/blob/main/schema/extensions.md).
This is done to avoid collisions with core or other extension schemas.
For example, a new sample extension would have a row in the table as follows:

| **Caption**   | **Name** | **UID** | **Notes**                         |
| ------------- | -------- | ------- | --------------------------------- |
| New Extension | new_ex   | 123     | The development schema extensions |

### Create your Extension's subdirectory:

To extend the schema, create a new subdirectory in the `extensions` directory,
and add a new `extension.json` file, which defines the extension's `name`
and `uid`. For example:

```
{
  "caption": "New Extension",
  "name": "new_ex",
  "uid": 123,
  "version": "0.0.0"
}
```

The extension's directory structure is the same as the top level schema directory, and it may contain the following files and subdirectories, depending on what type of extension is desired:

| Name                 | Description                                                                                                                                                                 |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| `main_skills.json`   | Create it to define new skill categories. Note, to avoid collisions with the categories defined in the core schema, the category IDs must be greater than or equal to 30.   |
| `main_domains.json`  | Create it to define new domain categories. Note, to avoid collisions with the categories defined in the core schema, the category IDs must be greater than or equal to 30.  |
| `main_features.json` | Create it to define new feature categories. Note, to avoid collisions with the categories defined in the core schema, the category IDs must be greater than or equal to 30. |
| `dictionary.json`    | Create it to define new attributes.                                                                                                                                         |
| `skills`             | Create it to define new skill classes.                                                                                                                                      |     |
| `domains`            | Create it to define new domain classes.                                                                                                                                     |     |
| `features`           | Create it to define new feature classes.                                                                                                                                    |     |
| `objects`            | Create it to define new objects.                                                                                                                                            |
| `profiles`           | Create it to define new profiles.                                                                                                                                           |

## Reporting Issues

Before reporting a new issue, please ensure that the issue was not already
reported or fixed by searching through our [issues
list](https://github.com/agntcy/oasf/issues).

When creating a new issue, please be sure to include a **title and clear
description**, as much relevant information as possible, and, if possible, a
test case.

**If you discover a security bug, please do not report it through GitHub.
Instead, please see security procedures in [SECURITY.md](/SECURITY.md).**

## Sending Pull Requests

Before sending a new pull request, take a look at existing pull requests and
issues to see if the proposed change or fix has been discussed in the past, or
if the change was already implemented but not yet released.

We expect new pull requests to include tests for any affected behavior, and, as
we follow semantic versioning, we may reserve breaking changes until the next
major version release.

## Developer’s Certificate of Origin

To improve tracking of who did what, we have introduced a “sign-off” procedure.
The sign-off is a line at the end of the explanation for the commit, which
certifies that you wrote it or otherwise have the right to pass it on as open
source work. We use the Developer Certificate of Origin (see
https://developercertificate.org/) for our sign-off procedure. You must include
a sign-off in the commit message of your pull request for it to be accepted. The
format for a sign-off is:

```
Signed-off-by: Random J Developer
<random@developer.example.org>
```

You can use the -s when you do a git commit to simplify including a properly
formatted sign-off in your commits. If you need to add your sign-off to a commit
you have already made, you will need to amend:

```
git commit --amend --signoff

```

## Other Ways to Contribute

We welcome anyone that wants to contribute to OASF to triage and
reply to open issues to help troubleshoot and fix existing bugs. Here is what
you can do:

- Help ensure that existing issues follows the recommendations from the
  _[Reporting Issues](#reporting-issues)_ section, providing feedback to the
  issue's author on what might be missing.
- Review and update the existing content of our
  [docs](https://docs.agntcy.org/oasf/open-agentic-schema-framework) with up-to-date
  instructions and code samples.
- Review existing pull requests, and testing patches against real existing
  applications that use `OASF`.
- Write a test, or add a missing test case to an existing test.

Thanks again for your interest on contributing to `OASF`!

:heart:
