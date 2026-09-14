import os
import uuid
from datetime import datetime
from flask import Flask, render_template, request, redirect, url_for, jsonify
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# REMEDIATION: Hardcoded secret replaced with environment variable
API_KEY = os.environ.get("APP_SECRET_KEY")

notes_db = [
    {
        "id": "init-1",
        "text": "Welcome to SecureNotes! DevSecOps pipeline active and remediated.",
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
]


# REMEDIATION: Extracted unified validation helper to resolve code smell
def validate_note_input(value: str) -> bool:
    """Validates that note input or id is non-empty."""
    return bool(value and value.strip())


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html", notes=notes_db)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "service": "securenotes",
        "timestamp": datetime.now().isoformat()
    }), 200


@app.route("/add", methods=["POST"])
def add_note():
    note_text = request.form.get("note", "").strip()

    if not validate_note_input(note_text):
        return redirect(url_for("index"))

    new_note = {
        "id": str(uuid.uuid4())[:8],
        "text": note_text,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    notes_db.insert(0, new_note)
    return redirect(url_for("index"))


@app.route("/delete/<string:note_id>", methods=["POST"])
def delete_note(note_id):
    if not validate_note_input(note_id):
        return redirect(url_for("index"))

    notes_db[:] = [note for note in notes_db if note["id"] != note_id]
    return redirect(url_for("index"))


if __name__ == "__main__":
    port = int(os.environ.get("FLASK_PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
