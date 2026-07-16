"""Stable, dependency-free canonical document schema."""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import json


@dataclass
class SourceRef:
    path: str
    source_type: str = "file"
    from_code: bool = False
    locator: str = ""


@dataclass
class ContentItem:
    content: str
    sources: list[SourceRef] = field(default_factory=list)
    inferred: bool = False
    manual_confirmation: bool = False
    locale: str = "zh-cn"
    confidence: float = 1.0
    quality_status: str = "unchecked"


@dataclass
class Section:
    key: str
    title: str
    items: list[ContentItem] = field(default_factory=list)
    children: list["Section"] = field(default_factory=list)


@dataclass
class Metadata:
    project_id: str = ""
    solution_name: str = ""
    solution_name_en: str = ""
    document_type: str = "deployment-guide"
    version: str = "1.0"
    site: str = "cn"
    locale: str = "zh-cn"
    author: str = ""
    generated_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    model_version: str = "offline-rules-v1"
    template_version: str = "idp-neutral-v1"
    source_files: list[str] = field(default_factory=list)


@dataclass
class Review:
    inferred_items: list[str] = field(default_factory=list)
    missing_items: list[str] = field(default_factory=list)
    manual_confirmation_items: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


@dataclass
class DocumentModel:
    metadata: Metadata = field(default_factory=Metadata)
    sections: list[Section] = field(default_factory=list)
    assets: dict[str, list[dict[str, Any]]] = field(default_factory=lambda: {"images": [], "tables": [], "code_blocks": []})
    review: Review = field(default_factory=Review)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    def save(self, path: str | Path) -> Path:
        p = Path(path); p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(self.to_dict(), ensure_ascii=False, indent=2), encoding="utf-8")
        return p

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "DocumentModel":
        def item(v):
            return ContentItem(**{**v, "sources": [SourceRef(**s) for s in v.get("sources", [])]})
        def section(v):
            return Section(v["key"], v["title"], [item(x) for x in v.get("items", [])], [section(x) for x in v.get("children", [])])
        return cls(Metadata(**data.get("metadata", {})), [section(x) for x in data.get("sections", [])], data.get("assets", {}), Review(**data.get("review", {})))

    @classmethod
    def load(cls, path: str | Path) -> "DocumentModel":
        return cls.from_dict(json.loads(Path(path).read_text(encoding="utf-8")))
