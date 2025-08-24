from flask import Blueprint, request, jsonify
from app import get_db
import json
from app.services.utils import error_response

bp = Blueprint("products", __name__, url_prefix="/products")

@bp.route("", methods=["GET"])
def get_products():
    db = get_db()
    cursor = db.execute("SELECT * FROM products")
    products = [dict(row) for row in cursor.fetchall()]
    return jsonify(products), 200

@bp.route("", methods=["POST"])
def add_product():
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
            product.get("product_description"),
        ),
    )
    db.commit()
    return jsonify({"message": "Product added successfully!"}), 201
