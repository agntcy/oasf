import skill_pb2 as _skill_pb2
import locator_pb2 as _locator_pb2
import extension_pb2 as _extension_pb2
import signature_pb2 as _signature_pb2
from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Record(_message.Message):
    __slots__ = ("name", "version", "schema_version", "description", "authors", "annotations", "created_at", "skills", "locators", "extensions", "signature", "previous_record_cid")
    class AnnotationsEntry(_message.Message):
        __slots__ = ("key", "value")
        KEY_FIELD_NUMBER: _ClassVar[int]
        VALUE_FIELD_NUMBER: _ClassVar[int]
        key: str
        value: str
        def __init__(self, key: _Optional[str] = ..., value: _Optional[str] = ...) -> None: ...
    NAME_FIELD_NUMBER: _ClassVar[int]
    VERSION_FIELD_NUMBER: _ClassVar[int]
    SCHEMA_VERSION_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    AUTHORS_FIELD_NUMBER: _ClassVar[int]
    ANNOTATIONS_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    SKILLS_FIELD_NUMBER: _ClassVar[int]
    LOCATORS_FIELD_NUMBER: _ClassVar[int]
    EXTENSIONS_FIELD_NUMBER: _ClassVar[int]
    SIGNATURE_FIELD_NUMBER: _ClassVar[int]
    PREVIOUS_RECORD_CID_FIELD_NUMBER: _ClassVar[int]
    name: str
    version: str
    schema_version: str
    description: str
    authors: _containers.RepeatedScalarFieldContainer[str]
    annotations: _containers.ScalarMap[str, str]
    created_at: str
    skills: _containers.RepeatedCompositeFieldContainer[_skill_pb2.Skill]
    locators: _containers.RepeatedCompositeFieldContainer[_locator_pb2.Locator]
    extensions: _containers.RepeatedCompositeFieldContainer[_extension_pb2.Extension]
    signature: _signature_pb2.Signature
    previous_record_cid: str
    def __init__(self, name: _Optional[str] = ..., version: _Optional[str] = ..., schema_version: _Optional[str] = ..., description: _Optional[str] = ..., authors: _Optional[_Iterable[str]] = ..., annotations: _Optional[_Mapping[str, str]] = ..., created_at: _Optional[str] = ..., skills: _Optional[_Iterable[_Union[_skill_pb2.Skill, _Mapping]]] = ..., locators: _Optional[_Iterable[_Union[_locator_pb2.Locator, _Mapping]]] = ..., extensions: _Optional[_Iterable[_Union[_extension_pb2.Extension, _Mapping]]] = ..., signature: _Optional[_Union[_signature_pb2.Signature, _Mapping]] = ..., previous_record_cid: _Optional[str] = ...) -> None: ...
