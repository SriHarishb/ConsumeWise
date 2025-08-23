from flask import Blueprint, request, Response, stream_with_context, jsonify
from werkzeug.exceptions import BadRequest
from app import get_db
from app.services.utils import encode_image_to_base64, error_response
from app.services.ollama_service import run_ollama

bp = Blueprint("health", __name__)

@bp.route("/gethealthsuggestion", methods=["POST"])
def get_health_suggestion():
    """
    Get health suggestions for a product based on user input.
    Accepts either JSON with barcode_number + diseases OR multipart form with image.
    """
    try:
        # --- Case 1: File Upload (multipart/form-data) ---
        if "image" in request.files:
            image_file = request.files["image"]
            encoded_image = encode_image_to_base64(image_file)

            # diseases could be sent as form field
            diseases = request.form.getlist("diseases") or None

            if not encoded_image:
                return error_response("No image provided", 400)

            prompt = (
                f"Scan this product image (base64): {encoded_image}. "
                f"The user has the following health concerns: {diseases}. "
                "Give health suggestions and advice for this product considering the health status of the user. "
                "Do not include any punctuation marks other than full stop and comma."
            )

        # --- Case 2: JSON Request (application/json) ---
        elif request.is_json:
            data = request.get_json()
            barcode_number = data.get("barcode_number")
            diseases = data.get("diseases")

            db = get_db()
            cursor = db.execute("SELECT * FROM products WHERE barcode_number=?", (barcode_number,))
            row = cursor.fetchone()
            product = dict(row) if row else None

            if not product:
                return error_response("Product not found", 404)

            prompt = (
                f"These are the product details: {product}. "
                f"The user has the following health concerns: {diseases}. "
                "Give health suggestions and advice for this specific product considering the health status of the user. "
                "Also consider the nutritional content and ingredients if provided and generate advice according to that. "
                "Do not include any punctuation marks other than full stop and comma."
            )

        else:
            return error_response("Unsupported request format. Use JSON or multipart/form-data.", 400)

        # --- Streaming Response (SSE format) ---
        def generate():
            for chunk in run_ollama(prompt, expect_json=False,stream=True):
                yield f"data: {chunk}\n\n"
            yield "event: end\ndata: [DONE]\n\n"

        return Response(stream_with_context(generate()), mimetype="text/event-stream")

    except BadRequest:
        return error_response("Invalid request format", 400)
    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)
