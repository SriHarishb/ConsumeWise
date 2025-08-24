import io


def parse_sse(response):
    """Convert Flask SSE streaming response into a single text string."""
    raw = b"".join(response.response).decode("utf-8")
    lines = raw.splitlines()
    # Keep only lines starting with "data:" and strip that part
    cleaned = "".join(line.replace("data: ", "") for line in lines if line.startswith("data:"))
    return cleaned


def test_health_suggestion_with_product(client, monkeypatch):
    # Insert product
    client.post("/products", json={
        "barcode_number": "22222",
        "item_name": "Test Health Product"
    })

    def fake_ollama_chat(*args, **kwargs):
        yield {"message": {"content": "Sample advice"}}

    monkeypatch.setattr("app.routes.health.run_ollama", fake_ollama_chat)

    res = client.post("/gethealthsuggestion", json={
        "barcode_number": "22222",
        "diseases": ["diabetes"]
    })

    assert res.status_code == 200
    data = parse_sse(res)
    assert "Sample advice" in data

def test_health_suggestion_with_image(client, monkeypatch):
    def fake_ollama_chat(*args, **kwargs):
        yield {"message": {"content": "Image-based advice"}}

    monkeypatch.setattr("app.routes.health.run_ollama", fake_ollama_chat)
    monkeypatch.setattr("app.routes.health.encode_image_to_base64", lambda f: "fake_base64")

    img = io.BytesIO(b"fake image data")
    res = client.post(
        "/gethealthsuggestion",
        data={"image": (img, "test.jpg")},
        content_type="multipart/form-data"
    )

    assert res.status_code == 200
    data = parse_sse(res)
    assert "Image-based advice" in data
