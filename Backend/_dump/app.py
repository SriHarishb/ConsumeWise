import os
import base64
import json
import sqlite3
from flask import Flask, jsonify, request, g, Response, stream_with_context
import ollama
from werkzeug.exceptions import BadRequest, InternalServerError
from dotenv import load_dotenv
from flask_swagger_ui import get_swaggerui_blueprint
import yaml

load_dotenv()

# App Config
app = Flask(__name__)

MODEL_NAME = os.getenv("OLLAMA_MODEL")
DB_PATH = os.getenv("SQLITE_DB", "products.db")  # default db file

# Path to your OpenAPI YAML file
SWAGGER_URL = "/docs"  # Swagger UI will be available at http://localhost:5000/docs
API_URL = "/static/openapi.yaml"  # Spec file will be served here

# Register Swagger UI blueprint
swaggerui_blueprint = get_swaggerui_blueprint(
    SWAGGER_URL,
    API_URL,
    config={"app_name": "Consumewise Product API"}
)
app.register_blueprint(swaggerui_blueprint, url_prefix=SWAGGER_URL)

# SQLite Helpers
def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db

@app.teardown_appcontext
def close_db(exception):
    db = g.pop("db", None)
    if db is not None:
        db.close()

def init_db():
    db = get_db()
    db.execute(
        """CREATE TABLE IF NOT EXISTS products (
               barcode_number TEXT PRIMARY KEY,
               item_name TEXT,
               brand TEXT,
               weight TEXT,
               ingredients TEXT,
               nutritional_info TEXT,
               product_description TEXT
           )"""
    )
    db.commit()

# Utility Functions
def encode_image_to_base64(image_file):
    """
    Encode an image file to a base64 string.
    Args:
        image_file: The image file to encode.
    Returns:
        A base64 encoded string representation of the image file, or None if the file is not provided.
    """
    if not image_file:
        return None
    return base64.b64encode(image_file.read()).decode("utf-8")

def run_ollama(prompt: str, expect_json: bool = False):
    """
    Run the Ollama model with the given prompt.
    Args:
        prompt: The prompt to send to the model.
        expect_json: Whether to expect a JSON response.
    Returns:
        The response from the model.
    """
    try:
        response = ollama.chat(
            model=MODEL_NAME,
            messages=[{"role": "user", "content": prompt}],
            format="json" if expect_json else None
        )
        if "message" in response and "content" in response["message"]:
            return response["message"]["content"]
        raise ValueError("No valid content in Ollama response")
    except Exception as e:
        raise InternalServerError(f"Ollama error: {str(e)}")

def error_response(message: str, code: int = 400):
    """
    Create a standardized error response.
    Args:
        message: The error message to include in the response.
        code: The HTTP status code to return.
    Returns:
        A JSON response with the error message and status code.
    """
    return jsonify({"error": message}), code

# Routes
@app.route(API_URL)
def openapi_spec():
    """
    Serve the OpenAPI specification file.
    Args:
        None
    Returns:
        A JSON response with the OpenAPI specification.
    """
    with open("openapi.yaml", "r") as f:
        spec = yaml.safe_load(f)
    return jsonify(spec)

@app.route('/products', methods=['GET'])
def get_products():
    """
    Get a list of all products.
    Args:
        None
    Returns:
        A JSON response with the list of products.
    """
    db = get_db()
    cursor = db.execute("SELECT * FROM products")
    products = [dict(row) for row in cursor.fetchall()]
    return jsonify(products), 200

@app.route('/products', methods=['POST'])
def add_product():
    """
    Add a new product.
    Args:
        None
    Returns:
        A JSON response indicating the result of the operation.
    """
    product = request.json
    if not product or "barcode_number" not in product:
        return error_response("Invalid product data: missing barcode_number")

    db = get_db()
    cursor = db.execute("SELECT 1 FROM products WHERE barcode_number=?", (product["barcode_number"],))
    if cursor.fetchone():
        return error_response("Product with this barcode already exists!", 400)

    db.execute(
        "INSERT INTO products (barcode_number, item_name, brand, weight, ingredients, nutritional_info, product_description) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            product.get("barcode_number"),
            product.get("item_name"),
            product.get("brand"),
            product.get("weight"),
            json.dumps(product.get("ingredients")),
            json.dumps(product.get("nutritional_info")),
            product.get("product_description")
        )
    )
    db.commit()
    return jsonify({"message": "Product added successfully!"}), 201


@app.route('/gethealthsuggestion', methods=['POST'])
def get_health_suggestion():
    """
    Stream health suggestions for a product using SSE.
    Returns:
        SSE response streaming the health suggestions.
    """
    try:
        image_file = request.files.get("image")
        encoded_image = encode_image_to_base64(image_file)
        data = request.get_json(force=True)
        barcode_number = data.get('barcode_number')
        diseases = data.get('diseases')

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
                    model=MODEL_NAME,
                    messages=[{"role": "user", "content": prompt}],
                    stream=True
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

@app.route("/extract_product_details", methods=["POST"])
def extract_product_details():
    """
    Extract product details from two images.
    Args:
        None
    Returns:
        A JSON response with the extracted product details.
    """
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
            "product_description (string), health_suggestion (string).\n"
            "All fields except health_suggestion should be taken only from the images.\n"
            "Generate health_suggestion considering the nutritional information and ingredients.\n"
            "Do not include any extra text, only return a valid JSON."
        )

        result = run_ollama(prompt, expect_json=True)
        return jsonify(json.loads(result)), 200

    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)

if __name__ == '__main__':
    with app.app_context():
        init_db()
    app.run(host='0.0.0.0', debug=True)
