import base64
from flask import jsonify

def encode_image_to_base64(image_file):
    if not image_file:
        return None
    return base64.b64encode(image_file.read()).decode("utf-8")

def error_response(message: str, code: int = 400):
    return jsonify({"error": message}), code
