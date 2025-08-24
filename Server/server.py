import os
import base64
import json
from flask import Flask, jsonify, request
from pymongo import MongoClient
import ollama
from werkzeug.exceptions import BadRequest, InternalServerError
from dotenv import load_dotenv
from flask_swagger_ui import get_swaggerui_blueprint
import yaml

load_dotenv()

# App Config

app = Flask(__name__)

MONGO_URI = os.getenv("MONGODB_URI")
DB_NAME = os.getenv("DB_NAME")
MODEL_NAME = os.getenv("OLLAMA_MODEL")
# Path to your OpenAPI YAML file
SWAGGER_URL = "/docs"  # Swagger UI will be available at http://localhost:5000/docs
API_URL = "/static/openapi.yaml"  # Spec file will be served here

client = MongoClient(MONGO_URI)
db = client[DB_NAME]
products_collection = db['products']


# Register Swagger UI blueprint
swaggerui_blueprint = get_swaggerui_blueprint(
    SWAGGER_URL,
    API_URL,
    config={
        "app_name": "Consumewise Product API"
    }
)
app.register_blueprint(swaggerui_blueprint, url_prefix=SWAGGER_URL)
# Utility Functions


def encode_image_to_base64(image_file):
    """Convert an uploaded image file to base64 string."""
    if not image_file:
        return None
    return base64.b64encode(image_file.read()).decode("utf-8")


def run_ollama(prompt: str, expect_json: bool = False):
    """Send a prompt to Ollama model and return the response."""
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
    """Return a consistent error response."""
    return jsonify({"error": message}), code


# Routes



# Serve the YAML file
@app.route(API_URL)
def openapi_spec():
    with open("openapi.yaml", "r") as f:
        spec = yaml.safe_load(f)
    return jsonify(spec)

@app.route('/products', methods=['GET'])
def get_products():
    """Retrieve all products in the database."""
    products = list(products_collection.find({}, {'_id': 0}))
    return jsonify(products), 200


@app.route('/products', methods=['POST'])
def add_product():
    """Insert a new product if it does not exist already."""
    product = request.json
    if not product or "barcode_number" not in product:
        return error_response("Invalid product data: missing barcode_number")

    barcode = product["barcode_number"]

    if products_collection.find_one({"barcode_number": barcode}):
        return error_response("Product with this barcode already exists!", 400)

    products_collection.insert_one(product)
    return jsonify({"message": "Product added successfully!"}), 201


@app.route('/gethealthsuggestion', methods=['POST'])
def get_health_suggestion():
    """
    Generate health suggestions for a product.
    Either uses product details from DB by barcode or scans provided image.
    """
    try:
        # Get image if provided
        image_file = request.files.get("image")
        encoded_image = encode_image_to_base64(image_file)

        data = request.get_json(force=True)
        barcode_number = data.get('barcode_number')
        diseases = data.get('diseases')

        product = products_collection.find_one({"barcode_number": barcode_number}, {'_id': 0})

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

        result = run_ollama(prompt, expect_json=False)
        return jsonify({"advice": result}), 200

    except BadRequest:
        return error_response("Invalid request format", 400)
    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)


@app.route("/extract_product_details", methods=["POST"])
def extract_product_details():
    """
    Extract product details from two uploaded images and return structured JSON.
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
    app.run(host='0.0.0.0', debug=True)
