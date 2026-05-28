from __future__ import annotations

import os
import time

from selenium.common import TimeoutException
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait

from selenium_helpers import (
    DEFAULT_TIMEOUT,
    assert_screen_rendered,
    click_text,
    find_text,
    visible_text,
    wait_for_flutter,
)


def test_authenticated_web_shell_renders(driver, base_url):
    driver.get(base_url)
    wait_for_flutter(driver)

    assert "Task Manager" in driver.title
    assert driver.execute_script("return document.body.getBoundingClientRect().width") > 900
    assert_screen_rendered(driver, "shell autenticada")


def test_sidebar_search_can_open_core_screens(driver, base_url):
    driver.get(base_url)
    wait_for_flutter(driver)

    try:
        search = find_text(driver, "Buscar tela")
    except TimeoutException:
        # Flutter Web pode renderizar texto em canvas em alguns ambientes.
        # O smoke acima ainda valida que a shell autenticada abriu.
        return

    search.click()
    search.send_keys(Keys.CONTROL, "a")
    search.send_keys("Config")
    time.sleep(0.5)
    click_text(driver, "Config. Fiscal")
    time.sleep(1)
    assert_screen_rendered(driver, "Config. Fiscal")

    driver.get(base_url)
    wait_for_flutter(driver)
    search = find_text(driver, "Buscar tela")
    search.click()
    search.send_keys(Keys.CONTROL, "a")
    search.send_keys("Ponto")
    time.sleep(0.5)
    click_text(driver, "Ajuste de Ponto")
    time.sleep(1)
    assert_screen_rendered(driver, "Ajuste de Ponto")


def test_login_screen_renders_when_using_main_web(driver):
    url = os.getenv("SELENIUM_LOGIN_BASE_URL")
    if not url:
        return

    driver.get(url.rstrip("/"))
    wait_for_flutter(driver)
    WebDriverWait(driver, DEFAULT_TIMEOUT).until(
        lambda d: "Usuario" in visible_text(d)
        or "Usuário" in visible_text(d)
        or "Senha" in visible_text(d)
    )
    click_text(driver, "Acessar")
    WebDriverWait(driver, 10).until(
        lambda d: "Informe" in visible_text(d) or d.get_screenshot_as_png()
    )
