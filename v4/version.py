#!/usr/bin/env python3
"""Single source of truth for HakPak4 versioning."""

from pathlib import Path


VERSION = Path(__file__).with_name("VERSION").read_text(encoding="utf-8").strip()