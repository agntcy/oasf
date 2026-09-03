# OASF Extensions Registry

The purpose of this file is to keep track of and avoid collisions in Extension `names` and `uid`s.

## Allocating a uid

Extensions allocate **downwards from 999**. A new extension takes the next unused uid below the lowest one already listed. Reserve it here, by pull request, before publishing the extension.

The `uid` must be **between 100 and 999**, and the metaschema enforces the lower bound. An extension's classes are numbered `(uid * 100 + category_uid) * 100 + class_uid`, while a core class is numbered `category_uid * 10000 + subcategory_uid * 100 + class_uid`. An extension uid below 100 therefore produces class identifiers indistinguishable from core ones — uid 1 with category 3 and class 1 yields `10301`, which is already `language_processing/language_generation/text_completion`.

Identifiers are packed two decimal digits per level, so this only holds while every `category_uid` and `class_uid` stays below 100. That is now enforced too: `class.schema.json` caps a class `uid` at 99, where it previously allowed 999 and a three-digit value silently overflowed into the neighbouring category.

The floor of 100 is therefore a reciprocal commitment: extensions stay at or above it, and the core taxonomy keeps its category uids below it. That leaves 900 extension uids and room for 99 categories in each of `skills`, `domains`, and `modules`, against the 18, 24, and 2 defined today. Category uids are scoped per family, so each grows independently.

`Repository` is optional. Use it when the extension schema is public. Leave it blank for private extensions or when the schema is not published.

| Caption     | Name    | UID     | Notes                                                | Repository                                    |
| ----------- | ------- | ------- | ---------------------------------------------------- | --------------------------------------------- |
| Development | dev     | **999** | The development (TODO) schema extensions             |                                               |
| Example     | example | **998** | Reference extension demonstrating the mechanism      | [schema/extensions/example](extensions/example/) |
