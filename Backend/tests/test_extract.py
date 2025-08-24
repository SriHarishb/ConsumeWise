import io
import json

def test_extract_product_details(client, monkeypatch):
    fake_response = json.dumps({
        "item_name": "Extracted Product",
        "brand": "Extracted Brand",
        "barcode_number": "33333",
        "weight": "250g",
        "ingredients": ["flour", "salt"],
        "nutritional_info": {"calories": "200"},
        "product_description": "Extracted description",
        "health_suggestion": "Healthy option"
    })

    monkeypatch.setattr("app.routes.extract.run_ollama", lambda *a, **k: fake_response)

    img1 = io.BytesIO(b"fake image1 data")
    img2 = io.BytesIO(b"fake image2 data")
    res = client.post(
        "/extract_product_details",
        data={"image1": (img1, "img1.jpg"), "image2": (img2, "img2.jpg")},
        content_type="multipart/form-data"
    )

    assert res.status_code == 200
    data = res.get_json()
    assert data["item_name"] == "Extracted Product"
    assert "health_suggestion" in data
