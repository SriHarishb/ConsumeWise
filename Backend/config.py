import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    MODEL_NAME = os.getenv("OLLAMA_MODEL", "llama2")
    DB_PATH = os.getenv("SQLITE_DB", "instance/products.db")
    SWAGGER_URL = "/docs"
    API_URL = "/static/openapi.yaml"
