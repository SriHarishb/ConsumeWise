import ollama
from werkzeug.exceptions import InternalServerError
from flask import current_app


def run_ollama(prompt: str, expect_json: bool = False, stream: bool = False):
    if stream:
        response = ollama.chat(
            model=current_app.config["MODEL_NAME"],
            messages=[{"role": "user", "content": prompt}],
            format="json" if expect_json else None,
            stream=True
        )
        for chunk in response:
            # Only yield actual content
            if "message" in chunk and "content" in chunk["message"]:
                yield chunk["message"]["content"]
        return
    try:
        response = ollama.chat(
            model=current_app.config["MODEL_NAME"],
            messages=[{"role": "user", "content": prompt}],
            format="json" if expect_json else None
        )
        if "message" in response and "content" in response["message"]:
            return response["message"]["content"]
        raise ValueError("No valid content in Ollama response")
    except Exception as e:
        raise InternalServerError(f"Ollama error: {str(e)}")
