import io

def test_health_suggestion_with_product(client, monkeypatch):
    # Insert product
    client.post("/products", json={
        "barcode_number": "22222",
        "item_name": "Test Health Product"
    })

    def fake_ollama_chat(*args, **kwargs):
        yield {"message": {"content": "Sample advice"}}

    monkeypatch.setattr("app.routes.health.ollama.chat", fake_ollama_chat)

    res = client.post("/gethealthsuggestion", json={
        "barcode_number": "22222",
        "diseases": ["diabetes"]
    })

    assert res.status_code == 200
    data = b"".join(res.response).decode("utf-8")
    assert "Sample advice" in data

def test_health_suggestion_with_image(client, monkeypatch):
    def fake_ollama_chat(*args, **kwargs):
        yield {"message": {"content": "Image-based advice"}}

    monkeypatch.setattr("app.routes.health.ollama.chat", fake_ollama_chat)

    img = io.BytesIO(b"fake image data")
    res = client.post(
        "/gethealthsuggestion",
        data={"image": (img, "test.jpg")},
        content_type="multipart/form-data"
    )

    assert res.status_code == 200
    data = b"".join(res.response).decode("utf-8")
    assert "Image-based advice" in data
