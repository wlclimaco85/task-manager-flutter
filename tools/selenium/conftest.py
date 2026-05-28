from __future__ import annotations

import os
import shutil
import subprocess
import threading
import time
import urllib.request
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.edge.options import Options as EdgeOptions


ROOT = Path(__file__).resolve().parents[2]
ARTIFACTS = Path(__file__).resolve().parent / ".artifacts"


def _flutter_bin() -> str:
    configured = os.getenv("FLUTTER_BIN")
    if configured:
        return configured

    fvm_flutter = ROOT / ".fvm" / "flutter_sdk" / "bin" / "flutter.bat"
    if fvm_flutter.exists():
        return str(fvm_flutter)

    local_flutter = ROOT / "flutter" / "bin" / "flutter.bat"
    if local_flutter.exists():
        return str(local_flutter)

    return shutil.which("flutter.bat") or shutil.which("flutter") or "flutter.bat"


def _wait_http_ok(url: str, timeout: int = 120) -> None:
    deadline = time.time() + timeout
    last_error: Exception | None = None
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=2) as response:
                if response.status < 500:
                    return
        except Exception as exc:  # noqa: BLE001
            last_error = exc
        time.sleep(1)
    raise RuntimeError(f"Flutter web-server nao respondeu em {url}: {last_error}")


class _QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, format: str, *args) -> None:  # noqa: A002
        return


@pytest.fixture(scope="session")
def base_url() -> str:
    external_url = os.getenv("SELENIUM_BASE_URL")
    if external_url:
        return external_url.rstrip("/")

    host = os.getenv("SELENIUM_HOST", "127.0.0.1")
    port = os.getenv("SELENIUM_PORT", "5200")
    target = os.getenv(
        "SELENIUM_FLUTTER_TARGET",
        "tools/selenium/selenium_web_app.dart",
    )
    renderer = os.getenv("SELENIUM_WEB_RENDERER")

    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    build_stdout = ARTIFACTS / "flutter-build-web.out.log"
    build_stderr = ARTIFACTS / "flutter-build-web.err.log"

    command = [_flutter_bin(), "build", "web", "-t", target]
    if renderer:
        command[command.index("-t"):command.index("-t")] = [
            "--web-renderer",
            renderer,
        ]

    if os.getenv("SELENIUM_SKIP_BUILD", "0") != "1":
        with build_stdout.open("w", encoding="utf-8") as stdout, build_stderr.open(
            "w", encoding="utf-8"
        ) as stderr:
            subprocess.run(command, cwd=ROOT, stdout=stdout, stderr=stderr, check=True)

    build_web = ROOT / "build" / "web"
    handler = partial(_QuietHandler, directory=str(build_web))
    try:
        httpd = ThreadingHTTPServer((host, int(port)), handler)
    except OSError:
        httpd = ThreadingHTTPServer((host, 0), handler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()

    actual_port = httpd.server_address[1]
    url = f"http://{host}:{actual_port}"
    try:
        _wait_http_ok(url)
        yield url
    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join(timeout=10)


@pytest.fixture()
def driver(request: pytest.FixtureRequest):
    browser = os.getenv("SELENIUM_BROWSER", "chrome").lower()
    headless = os.getenv("SELENIUM_HEADLESS", "1") != "0"

    if browser == "edge":
        options = EdgeOptions()
        if headless:
            options.add_argument("--headless=new")
        options.add_argument("--window-size=1440,1000")
        drv = webdriver.Edge(options=options)
    else:
        options = ChromeOptions()
        if headless:
            options.add_argument("--headless=new")
        options.add_argument("--window-size=1440,1000")
        options.add_argument("--disable-gpu")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        drv = webdriver.Chrome(options=options)

    drv.set_page_load_timeout(60)
    drv.implicitly_wait(1)
    yield drv

    if hasattr(request.node, "rep_call") and request.node.rep_call.failed:
        ARTIFACTS.mkdir(parents=True, exist_ok=True)
        screenshot = ARTIFACTS / f"{request.node.name}.png"
        drv.save_screenshot(str(screenshot))

    drv.quit()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    setattr(item, f"rep_{call.when}", outcome.get_result())
