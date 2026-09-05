"""Canonical JSON serialization for .sllicense payloads (design section 3).

Must stay byte-for-byte identical to
``smart-livestock-server/.../licensing/infrastructure/CanonicalJsonSerializer.java``
and is pinned by ``license-issuer/test-vectors/canonical-json-v1.json``.

Rules:
- UTF-8 encoding
- object keys sorted lexicographically, recursively (Java ``String`` order,
  i.e. UTF-16 code unit order)
- compact separators, no whitespace or newlines
- instants rendered as UTC ``yyyy-MM-dd'T'HH:mm:ss'Z'`` strings
- integral numbers without a decimal point
- ``null`` map entries are omitted; ``null`` elsewhere is rejected
- non-integral floats are rejected (payloads only carry integers/strings/bools)
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Iterable

CANONICAL_ENCODING = "utf-8"


class CanonicalJsonError(ValueError):
    """Raised when a value tree cannot be canonicalized."""


def canonical_instant(value: str) -> str:
    """Convert an ISO-8601 instant to the canonical UTC form.

    Mirrors Java ``DateTimeFormatter("yyyy-MM-dd'T'HH:mm:ss'Z'")`` with
    ``truncatedTo(SECONDS)``: fractional seconds are dropped.
    """
    if not isinstance(value, str) or not value.strip():
        raise CanonicalJsonError("instant value must be a non-empty string")
    text = value.strip()
    if text.endswith(("Z", "z")):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError as exc:
        raise CanonicalJsonError(f"invalid ISO-8601 instant: {value!r}") from exc
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    utc = parsed.astimezone(timezone.utc)
    return utc.strftime("%Y-%m-%dT%H:%M:%SZ")


def apply_instant_keys(value: Any, instant_keys: Iterable[str]) -> Any:
    """Recursively convert values under the given key names to canonical
    instant strings. Input structures cannot carry typed instants, so shared
    test vectors declare the keys that must be converted before serialization.
    """
    keys = set(instant_keys)
    if not keys:
        return value
    return _convert(value, keys)


def _convert(value: Any, keys: set) -> Any:
    if isinstance(value, dict):
        converted = {}
        for key, item in value.items():
            if key in keys and isinstance(item, str):
                converted[key] = canonical_instant(item)
            else:
                converted[key] = _convert(item, keys)
        return converted
    if isinstance(value, list):
        return [_convert(item, keys) for item in value]
    return value


def _normalize(value: Any) -> Any:
    """Validate and normalize a value tree so ``json.dumps`` output matches the
    Java serializer byte-for-byte."""
    if value is None:
        raise CanonicalJsonError("null values are not part of the canonical form")
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        # Java renders mathematically integral numbers without a decimal point.
        if value.is_integer():
            return int(value)
        raise CanonicalJsonError(
            "non-integral floats are not part of the license canonical form"
        )
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        normalized = {}
        for key, item in value.items():
            if not isinstance(key, str):
                raise CanonicalJsonError("object keys must be strings")
            if item is None:
                # Canonical form omits entries with absent values (Java parity).
                continue
            normalized[key] = _normalize(item)
        return normalized
    if isinstance(value, (list, tuple)):
        normalized = []
        for item in value:
            if item is None:
                raise CanonicalJsonError("arrays must not contain null values")
            normalized.append(_normalize(item))
        return normalized
    raise CanonicalJsonError(
        f"unsupported canonical JSON value type: {type(value).__name__}"
    )


def _sort_key(key: str) -> bytes:
    # Java TreeMap orders strings by UTF-16 code units; encoding to utf-16-be
    # reproduces that exact byte order (differs from code-point order only for
    # supplementary-plane keys, but keep the semantics identical anyway).
    return key.encode("utf-16-be")


def canonical_dumps(value: Any) -> str:
    """Serialize a value tree to the canonical JSON text form."""
    normalized = _normalize(value)
    return _dumps_sorted(normalized)


def _dumps_sorted(normalized: Any) -> str:
    # json.dumps(sort_keys=True) sorts by code point; re-sort with UTF-16
    # semantics by pre-building an ordered dict instead.
    return json.dumps(
        _sort_dicts(normalized),
        ensure_ascii=False,
        separators=(",", ":"),
    )


def _sort_dicts(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: _sort_dicts(value[key])
            for key in sorted(value.keys(), key=_sort_key)
        }
    if isinstance(value, list):
        return [_sort_dicts(item) for item in value]
    return value


def canonical_bytes(value: Any) -> bytes:
    """Serialize a value tree to canonical JSON bytes (the signing input)."""
    return canonical_dumps(value).encode(CANONICAL_ENCODING)
