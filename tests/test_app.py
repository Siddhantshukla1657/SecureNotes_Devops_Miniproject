import os
import sys
import pytest

# Ensure application root is on Python sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import app as app_module
from app import app


@pytest.fixture
def client():
    """Test client fixture for Flask."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture(autouse=True)
def reset_notes():
    """Reset the in-memory notes store before each test."""
    app_module.notes_db.clear()
    app_module.notes_db.append({
        "id": "test-1",
        "text": "Existing test note",
        "created_at": "2026-09-14 12:00:00"
    })


def test_health_check(client):
    """Test that /health returns 200 OK and expected JSON payload."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "ok"
    assert data["service"] == "securenotes"
    assert "timestamp" in data


def test_index_page(client):
    """Test that GET / returns the rendered HTML page."""
    response = client.get("/")
    assert response.status_code == 200
    assert b"SecureNotes" in response.data
    assert b"Existing test note" in response.data


def test_add_note_success(client):
    """Test creating a new note via POST /add."""
    response = client.post("/add", data={"note": "Automated pipeline test note"}, follow_redirects=True)
    assert response.status_code == 200
    assert b"Automated pipeline test note" in response.data
    assert len(app_module.notes_db) == 2


def test_add_note_empty_rejected(client):
    """Test submitting an empty note is safely rejected."""
    initial_count = len(app_module.notes_db)
    response = client.post("/add", data={"note": "   "}, follow_redirects=True)
    assert response.status_code == 200
    assert len(app_module.notes_db) == initial_count


def test_delete_note_success(client):
    """Test deleting an existing note via POST /delete/<id>."""
    assert len(app_module.notes_db) == 1
    response = client.post("/delete/test-1", follow_redirects=True)
    assert response.status_code == 200
    assert len(app_module.notes_db) == 0
    assert b"No active notes" in response.data


def test_delete_note_nonexistent(client):
    """Test deleting a non-existent note id is a graceful no-op."""
    initial_count = len(app_module.notes_db)
    response = client.post("/delete/non-existent-id-999", follow_redirects=True)
    assert response.status_code == 200
    assert len(app_module.notes_db) == initial_count
