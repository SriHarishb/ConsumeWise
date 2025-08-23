import io
import json
import pytest
from Backend.dump.app import app, init_db, get_db

@pytest.fixture(scope="module")
def client():
    # Setup
    with app.app_context():
        init_db()
        db = get_db()
        db.execute("DELETE FROM products")  # clean table
        db.commit()

    with app.test_client() as client:
        yield client

def test_add_product(client):
    product = {
        "barcode_number": "1234567890",
        "item_name": "Test Product",
        "brand": "Test Brand",
        "weight": "100g",
        "ingredients": ["sugar", "salt"],
        "nutritional_info": {"calories": "200"},
        "product_description": "A test product"
    }
    response = client.post("/products", json=product)
    assert response.status_code == 201
    assert response.json["message"] == "Product added successfully!"

def test_get_products(client):
    response = client.get("/products")
    assert response.status_code == 200
    products = response.get_json()
    assert isinstance(products, list)
    assert products[0]["item_name"] == "Test Product"

def test_health_suggestion_with_product(client, monkeypatch):
    # Fake streaming generator
    def fake_stream(*args, **kwargs):
        yield {"message": {"content": "Sample advice"}}

    # Patch ollama.chat instead of run_ollama
    import Backend.dump.app as app
    monkeypatch.setattr(app.ollama, "chat", fake_stream)

    response = client.post("/gethealthsuggestion", json={
        "barcode_number": "1234567890",
        "diseases": ["diabetes"]
    })

    assert response.status_code == 200
    data = b"".join(response.response).decode("utf-8")

    # Since SSE wraps it as "data: ..."
    assert "Sample advice" in data
    assert data.startswith("data:")  # check it's proper SSE format



def test_extract_product_details(client, monkeypatch):
    # Patch run_ollama to avoid calling real Ollama
    fake_result = json.dumps({
        "item_name": "Mock Product",
        "brand": "Mock Brand",
        "barcode_number": "9876543210",
        "weight": "200g",
        "ingredients": ["mock1", "mock2"],
        "nutritional_info": {"fat": "10g"},
        "product_description": "Mocked description",
        "health_suggestion": "Mocked suggestion"
    })
    monkeypatch.setattr("app.run_ollama", lambda *args, **kwargs: fake_result)

    data = {
        "image1": (io.BytesIO(b"fake image data"), "image1.jpg"),
        "image2": (io.BytesIO(b"fake image data"), "image2.jpg"),
    }
    response = client.post("/extract_product_details", data=data, content_type="multipart/form-data")
    assert response.status_code == 200
    result = response.get_json()
    assert result["item_name"] == "Mock Product"
