import json

def test_add_and_get_product(client):
    product = {
        "barcode_number": "12345",
        "item_name": "Test Product",
        "brand": "Test Brand",
        "weight": "500g",
        "ingredients": ["sugar", "salt"],
        "nutritional_info": {"calories": "100"},
        "product_description": "Sample description"
    }

    # Add product
    res = client.post("/products", json=product)
    assert res.status_code == 201
    assert res.get_json()["message"] == "Product added successfully!"

    # Retrieve product list
    res = client.get("/products")
    assert res.status_code == 200
    products = res.get_json()
    assert isinstance(products, list)
    assert products[0]["barcode_number"] == "12345"

def test_add_duplicate_product(client):
    product = {
        "barcode_number": "11111",
        "item_name": "Duplicate Product"
    }
    client.post("/products", json=product)

    res = client.post("/products", json=product)
    assert res.status_code == 400
    assert "already exists" in res.get_json()["error"]
