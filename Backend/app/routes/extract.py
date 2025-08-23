from flask import Blueprint, request, jsonify
from app.services.utils import encode_image_to_base64, error_response
from app.services.ollama_service import run_ollama
import json

bp = Blueprint("extract", __name__)

@bp.route("/extract_product_details", methods=["POST"])
def extract_product_details():
    try:
        if "image1" not in request.files or "image2" not in request.files:
            return error_response("Both image1 and image2 files must be provided", 400)

        encoded_image1 = encode_image_to_base64(request.files["image1"])
        encoded_image2 = encode_image_to_base64(request.files["image2"])

        prompt = (
            f"Here are two images of a product in base64 format:\n\n"
            f"Image 1: {encoded_image1}\n\n"
            f"Image 2: {encoded_image2}\n\n"
            "Extract the complete product details and return them strictly as a JSON object with the following keys:\n"
            "item_name (string), brand (string), barcode_number (string), weight (string),\n"
            "ingredients (array of strings), nutritional_info (object with key-value pairs),\n"
            "product_description (string)\n"
            "Do not include any extra text, only return a valid JSON."
        )

        result = run_ollama(prompt, expect_json=True)
        return jsonify(json.loads(result)), 200

    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)
