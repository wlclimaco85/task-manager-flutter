from __future__ import annotations

import os
import time

from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


DEFAULT_TIMEOUT = int(os.getenv("SELENIUM_TIMEOUT", "45"))


def wait_for_flutter(driver) -> None:
    WebDriverWait(driver, DEFAULT_TIMEOUT).until(
        lambda d: d.execute_script(
            """
            return Boolean(
              document.querySelector('flt-glass-pane') ||
              document.querySelector('flutter-view') ||
              document.querySelector('flt-semantics-host')
            );
            """
        )
    )
    time.sleep(1)


def visible_text(driver) -> str:
    return driver.execute_script("return document.body.innerText || ''") or ""


def find_text(driver, text: str, timeout: int = 8):
    xpath_literal = repr(text)
    xpath = (
        f"//*[contains(normalize-space(.), {xpath_literal}) "
        f"or contains(@aria-label, {xpath_literal})]"
    )
    return WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.XPATH, xpath))
    )


def click_text(driver, text: str) -> None:
    element = find_text(driver, text)
    driver.execute_script("arguments[0].scrollIntoView({block:'center'});", element)
    driver.execute_script("arguments[0].click();", element)


def assert_screen_rendered(driver, label: str) -> None:
    png = driver.get_screenshot_as_png()
    assert len(png) > 9000, f"Tela '{label}' parece nao ter renderizado conteudo visual"
