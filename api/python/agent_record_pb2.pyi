from google.api import annotations_pb2 as _annotations_pb2
from google.protobuf import descriptor_pb2 as _descriptor_pb2
from google.protobuf import empty_pb2 as _empty_pb2
from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Annotations(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class AgentSignature(_message.Message):
    __slots__ = ("algorithm", "annotations", "certificate", "content_bundle", "content_type", "signature", "signed_at")
    ALGORITHM_FIELD_NUMBER: _ClassVar[int]
    ANNOTATIONS_FIELD_NUMBER: _ClassVar[int]
    CERTIFICATE_FIELD_NUMBER: _ClassVar[int]
    CONTENT_BUNDLE_FIELD_NUMBER: _ClassVar[int]
    CONTENT_TYPE_FIELD_NUMBER: _ClassVar[int]
    SIGNATURE_FIELD_NUMBER: _ClassVar[int]
    SIGNED_AT_FIELD_NUMBER: _ClassVar[int]
    algorithm: str
    annotations: Annotations
    certificate: str
    content_bundle: str
    content_type: str
    signature: str
    signed_at: str
    def __init__(self, algorithm: _Optional[str] = ..., annotations: _Optional[_Union[Annotations, _Mapping]] = ..., certificate: _Optional[str] = ..., content_bundle: _Optional[str] = ..., content_type: _Optional[str] = ..., signature: _Optional[str] = ..., signed_at: _Optional[str] = ...) -> None: ...

class Data(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class BaseFeature(_message.Message):
    __slots__ = ("annotations", "data", "name", "version")
    ANNOTATIONS_FIELD_NUMBER: _ClassVar[int]
    DATA_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    VERSION_FIELD_NUMBER: _ClassVar[int]
    annotations: Annotations
    data: Data
    name: str
    version: str
    def __init__(self, annotations: _Optional[_Union[Annotations, _Mapping]] = ..., data: _Optional[_Union[Data, _Mapping]] = ..., name: _Optional[str] = ..., version: _Optional[str] = ...) -> None: ...

class BaseSkill(_message.Message):
    __slots__ = ("annotations", "id", "name")
    ANNOTATIONS_FIELD_NUMBER: _ClassVar[int]
    ID_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    annotations: Annotations
    id: int
    name: str
    def __init__(self, annotations: _Optional[_Union[Annotations, _Mapping]] = ..., id: _Optional[int] = ..., name: _Optional[str] = ...) -> None: ...

class Locator(_message.Message):
    __slots__ = ("annotations", "digest", "size", "type", "url")
    ANNOTATIONS_FIELD_NUMBER: _ClassVar[int]
    DIGEST_FIELD_NUMBER: _ClassVar[int]
    SIZE_FIELD_NUMBER: _ClassVar[int]
    TYPE_FIELD_NUMBER: _ClassVar[int]
    URL_FIELD_NUMBER: _ClassVar[int]
    annotations: Annotations
    digest: str
    size: int
    type: str
    url: str
    def __init__(self, annotations: _Optional[_Union[Annotations, _Mapping]] = ..., digest: _Optional[str] = ..., size: _Optional[int] = ..., type: _Optional[str] = ..., url: _Optional[str] = ...) -> None: ...

class AgentRecord(_message.Message):
    __slots__ = ("annotations", "authors", "created_at", "description", "extensions", "locators", "name", "previous_record_cid", "schema_version", "signature", "skills", "version")
    ANNOTATIONS_FIELD_NUMBER: _ClassVar[int]
    AUTHORS_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    EXTENSIONS_FIELD_NUMBER: _ClassVar[int]
    LOCATORS_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    PREVIOUS_RECORD_CID_FIELD_NUMBER: _ClassVar[int]
    SCHEMA_VERSION_FIELD_NUMBER: _ClassVar[int]
    SIGNATURE_FIELD_NUMBER: _ClassVar[int]
    SKILLS_FIELD_NUMBER: _ClassVar[int]
    VERSION_FIELD_NUMBER: _ClassVar[int]
    annotations: Annotations
    authors: _containers.RepeatedScalarFieldContainer[str]
    created_at: str
    description: str
    extensions: _containers.RepeatedCompositeFieldContainer[BaseFeature]
    locators: _containers.RepeatedCompositeFieldContainer[Locator]
    name: str
    previous_record_cid: str
    schema_version: str
    signature: AgentSignature
    skills: _containers.RepeatedCompositeFieldContainer[BaseSkill]
    version: str
    def __init__(self, annotations: _Optional[_Union[Annotations, _Mapping]] = ..., authors: _Optional[_Iterable[str]] = ..., created_at: _Optional[str] = ..., description: _Optional[str] = ..., extensions: _Optional[_Iterable[_Union[BaseFeature, _Mapping]]] = ..., locators: _Optional[_Iterable[_Union[Locator, _Mapping]]] = ..., name: _Optional[str] = ..., previous_record_cid: _Optional[str] = ..., schema_version: _Optional[str] = ..., signature: _Optional[_Union[AgentSignature, _Mapping]] = ..., skills: _Optional[_Iterable[_Union[BaseSkill, _Mapping]]] = ..., version: _Optional[str] = ...) -> None: ...
