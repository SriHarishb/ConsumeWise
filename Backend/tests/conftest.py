import pytest
from app import init_app, init_db
from config import Config

class TestConfig(Config):
    TESTING = True
    DB_PATH = ":memory:"  # in-memory DB for tests
    SCHEMA_PATH = "Backend/schema.sql"
    INIT_DB_ON_STARTUP = False  # we’ll run manually in tests

@pytest.fixture
def client():
    app = init_app(TestConfig)

    with app.app_context():
        # Fresh schema for every test session
        init_db(app)

        with app.test_client() as client:
            yield client
