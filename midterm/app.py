import os
from datetime import datetime

from flask import Flask, jsonify, render_template, request


def create_app() -> Flask:
    app = Flask(__name__)
    app.config["SECRET_MESSAGE"] = os.getenv("SECRET_MESSAGE", "DevOps Midterm App")

    @app.get("/")
    def index():
        return render_template("index.html", message=app.config["SECRET_MESSAGE"])

    @app.get("/hello/<name>")
    def hello(name: str):
        return jsonify(
            {
                "message": f"Hello, {name}!",
                "timestamp": datetime.utcnow().isoformat() + "Z",
            }
        )

    @app.post("/submit")
    def submit():
        user_name = request.form.get("name", "").strip()
        task = request.form.get("task", "").strip()
        if not user_name or not task:
            return jsonify({"status": "error", "detail": "name and task are required"}), 400

        return jsonify(
            {
                "status": "success",
                "detail": f"Task '{task}' submitted by {user_name}",
            }
        )

    @app.get("/health")
    def health():
        return jsonify({"status": "ok"}), 200

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
