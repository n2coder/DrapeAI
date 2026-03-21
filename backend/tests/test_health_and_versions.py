"""
Tests: Health check + Python / dependency version constraints.
"""
import sys
import importlib.metadata
import pytest


# ── Python version ────────────────────────────────────────────────────────

def test_python_version_minimum():
    """Must run on Python 3.11+."""
    assert sys.version_info >= (3, 11), (
        f"Python 3.11+ required, got {sys.version_info}"
    )


def test_python_version_not_313_plus():
    """
    imghdr was removed in 3.13; while we've deleted that import the test
    documents that we intentionally target 3.11/3.12.
    """
    assert sys.version_info < (3, 13), (
        "Running on Python 3.13+ — verify all stdlib imports are still valid"
    )


# ── Key dependency versions ───────────────────────────────────────────────

@pytest.mark.parametrize("package,min_version", [
    ("fastapi",          "0.109.0"),
    ("pydantic",         "2.7.0"),
    ("pydantic-settings","2.3.0"),
    ("motor",            "3.6.0"),
    ("python-jose",      "3.3.0"),
    ("firebase-admin",   "6.4.0"),
    ("cloudinary",       "1.38.0"),
    ("httpx",            "0.26.0"),
    ("slowapi",          "0.1.9"),
    ("bleach",           "6.1.0"),
])
def test_dependency_installed(package, min_version):
    """Every critical dependency is installed at or above its pinned version."""
    installed = importlib.metadata.version(package)
    from packaging.version import Version
    assert Version(installed) >= Version(min_version), (
        f"{package}: installed={installed}, required>={min_version}"
    )


# ── Health endpoint (live API call to Render) ─────────────────────────────

def test_live_health_endpoint():
    """
    GET /health → 200, success=True.
    This hits the actual deployed backend on Render.
    """
    import httpx
    base = "https://drapeai-wnum.onrender.com"
    try:
        r = httpx.get(f"{base}/health", timeout=20)
        assert r.status_code == 200, f"Expected 200, got {r.status_code}"
        body = r.json()
        assert body.get("success") is True
        assert body.get("status") == "ok"
        assert "version" in body
        print(f"\n  Live health: {body}")
    except httpx.ConnectError:
        pytest.skip("Render backend unreachable — skipping live test")
    except httpx.TimeoutException:
        pytest.skip("Render cold-start timeout — skipping live test")
