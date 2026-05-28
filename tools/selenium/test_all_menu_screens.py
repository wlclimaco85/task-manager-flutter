from __future__ import annotations

import os
import re
import time
from pathlib import Path
from urllib.parse import quote

import pytest

from selenium_helpers import assert_screen_rendered, wait_for_flutter


ROOT = Path(__file__).resolve().parents[2]


def _menu_items() -> list[tuple[str, str, int]]:
    source = (ROOT / "lib" / "utils" / "menu_config.dart").read_text(
        encoding="utf-8",
        errors="replace",
    )
    pattern = re.compile(
        r"MenuItem\(\s*"
        r"id:\s*'(?P<id>[^']+)'\s*,\s*"
        r"label:\s*'(?P<label>[^']+)'\s*,\s*"
        r"icon:\s*FontAwesomeIcons\.[^,]+,\s*"
        r"screenIndex:\s*(?P<index>-?\d+)\s*\)",
        re.MULTILINE,
    )

    items: list[tuple[str, str, int]] = []
    seen: set[str] = set()
    for match in pattern.finditer(source):
        item_id = match.group("id")
        label = match.group("label")
        index = int(match.group("index"))
        if index < 0 or item_id in seen:
            continue
        seen.add(item_id)
        items.append((item_id, label, index))
    return items


@pytest.mark.skipif(
    os.getenv("SELENIUM_ALL_SCREENS") != "1",
    reason="Use -AllScreens para rodar todas as telas do menu.",
)
def test_all_menu_screens_open_by_menu_index(driver, base_url):
    failures: list[str] = []
    items = []
    seen_indexes: set[int] = set()
    for item in _menu_items():
        if item[2] in seen_indexes:
            continue
        seen_indexes.add(item[2])
        items.append(item)

    limit = int(os.getenv("SELENIUM_ALL_SCREENS_LIMIT", "0"))
    if limit > 0:
        items = items[:limit]

    assert items, "Nenhum MenuItem encontrado em lib/utils/menu_config.dart"

    for item_id, label, index in items:
        try:
            driver.get(f"{base_url}/?screen={index}&case={quote(item_id)}")
            wait_for_flutter(driver)
            time.sleep(0.8)
            assert_screen_rendered(driver, label)
        except Exception as exc:  # noqa: BLE001
            failures.append(f"{item_id} [{index}] {label}: {exc}")

    assert not failures, "Falhas ao abrir telas:\n" + "\n".join(failures)
