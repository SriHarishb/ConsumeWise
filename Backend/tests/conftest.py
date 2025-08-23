import pytest
import tempfile
import os
from app import init_app, init_db
from config import Config


@pytest.fixture
def client():
    # Create a temporary SQLite file
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        db_path = tmp.name

    # Define a fresh config for this test run
    class _TestConfig(Config):
        TESTING = True
        INIT_DB_ON_STARTUP = False
        DB_PATH = db_path
        SCHEMA_PATH = os.path.join(os.path.dirname(__file__), "..", "schema.sql")

    app = init_app(_TestConfig)

    # Push app context
    ctx = app.app_context()
    ctx.push()

    # Init schema
    init_db(app)

    yield app.test_client()

    # Teardown
    ctx.pop()
    os.unlink(db_path)
