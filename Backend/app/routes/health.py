from flask import Blueprint, request, Response, stream_with_context
from werkzeug.exceptions import BadRequest
from app import get_db
from app.services.utils import encode_image_to_base64, error_response
import ollama
from flask import current_app

bp = Blueprint("health", __name__)

@bp.route("/gethealthsuggestion", methods=["POST"])
def get_health_suggestion():
    try:
        image_file = request.files.get("image")
        encoded_image = encode_image_to_base64(image_file)
        data = request.get_json(force=True)
        barcode_number = data.get("barcode_number")
        diseases = data.get("diseases")

        db = get_db()
        cursor = db.execute("SELECT * FROM products WHERE barcode_number=?", (barcode_number,))
        row = cursor.fetchone()
        product = dict(row) if row else None

        if not product and not encoded_image:
            return error_response("Product not found and no image provided", 400)

        if product:
            prompt = (
                f"These are the product details: {product}. "
                f"The user has the following health concerns: {diseases}. "
                "Give health suggestions and advice for this specific product considering the health status of the user. "
                "Also consider the nutritional content and ingredients if provided and generate advice according to that. "
                "Do not include any punctuation marks other than full stop and comma."
            )
        else:
            prompt = (
                f"Scan this product image (base64): {encoded_image}. "
                f"The user has the following health concerns: {diseases}. "
                "Give health suggestions and advice for this product considering the health status of the user. "
                "Do not include any punctuation marks other than full stop and comma."
            )

        def event_stream():
            try:
                for chunk in ollama.chat(
                    model=current_app.config["MODEL_NAME"],
                    messages=[{"role": "user", "content": prompt}],
                    stream=True,
                ):
                    if "message" in chunk and "content" in chunk["message"]:
                        text = chunk["message"]["content"]
                        yield f"data: {text}\n\n"
                yield "event: end\ndata: [DONE]\n\n"
            except Exception as e:
                yield f"event: error\ndata: {str(e)}\n\n"

        return Response(stream_with_context(event_stream()), mimetype="text/event-stream")

    except BadRequest:
        return error_response("Invalid request format", 400)
    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)
