from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional

DESCRIPTOR: _descriptor.FileDescriptor

class Signature(_message.Message):
    __slots__ = ("annotations", "signed_at", "algorithm", "signature", "certificate", "content_type", "content_bundle")
    class AnnotationsEntry(_message.Message):
        __slots__ = ("key", "value")
        KEY_FIELD_NUMBER: _ClassVar[int]
        VALUE_FIELD_NUMBER: _ClassVar[int]
        key: str
        value: str
        def __init__(self, key: _Optional[str] = ..., value: _Optional[str] = ...) -> None: ...
    ANNOTATIONS_FIELD_NUMBER: _ClassVar[int]
    SIGNED_AT_FIELD_NUMBER: _ClassVar[int]
    ALGORITHM_FIELD_NUMBER: _ClassVar[int]
    SIGNATURE_FIELD_NUMBER: _ClassVar[int]
    CERTIFICATE_FIELD_NUMBER: _ClassVar[int]
    CONTENT_TYPE_FIELD_NUMBER: _ClassVar[int]
    CONTENT_BUNDLE_FIELD_NUMBER: _ClassVar[int]
    annotations: _containers.ScalarMap[str, str]
    signed_at: str
    algorithm: str
    signature: str
    certificate: str
    content_type: str
    content_bundle: str
    def __init__(self, annotations: _Optional[_Mapping[str, str]] = ..., signed_at: _Optional[str] = ..., algorithm: _Optional[str] = ..., signature: _Optional[str] = ..., certificate: _Optional[str] = ..., content_type: _Optional[str] = ..., content_bundle: _Optional[str] = ...) -> None: ...
