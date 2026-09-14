import os
import uuid
from datetime import datetime
from flask import Flask, render_template, request, redirect, url_for, jsonify
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# SEEDED VULNERABILITY #1: Hardcoded Secret Key (SonarCloud Finding)
API_KEY = "sk-test-12345"

notes_db = [
    {
        "id": "init-1",
        "text": "Welcome to SecureNotes! DevSecOps pipeline active.",
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
]


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
    if not API_KEY:
        return redirect(url_for("index"))

    note_text = request.form.get("note", "").strip()

    # Seeded duplicate validation logic (instance 1)
    if not note_text or len(note_text) == 0:
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
    if not API_KEY:
        return redirect(url_for("index"))

    # Seeded duplicate validation logic (instance 2)
    if not note_id or len(note_id.strip()) == 0:
        return redirect(url_for("index"))

    notes_db[:] = [note for note in notes_db if note["id"] != note_id]
    return redirect(url_for("index"))


if __name__ == "__main__":
    port = int(os.environ.get("FLASK_PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
