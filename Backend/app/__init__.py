from flask import Flask, g, current_app
import sqlite3
from flask_swagger_ui import get_swaggerui_blueprint

db = None

def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(current_app.config["DB_PATH"],uri=True)
        g.db.row_factory = sqlite3.Row
    return g.db

def close_db(e=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()

def init_db(app):
    with app.app_context():
        db = get_db()
        with open(app.config["SCHEMA_PATH"], "r") as f:
            db.executescript(f.read())

def init_app(config_class):
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_object(config_class)

    # Blueprints
    from app.routes.products import bp as products_bp
    from app.routes.health import bp as health_bp
    from app.routes.extract import bp as extract_bp

    app.register_blueprint(products_bp)
    app.register_blueprint(health_bp)
    app.register_blueprint(extract_bp)

    # Swagger UI
    swaggerui_bp = get_swaggerui_blueprint(
        app.config["SWAGGER_URL"],
        app.config["API_URL"],
        config={"app_name": "Consumewise Product API"}
    )
    app.register_blueprint(swaggerui_bp, url_prefix=app.config["SWAGGER_URL"])

    # DB lifecycle
    app.teardown_appcontext(close_db)
    init_db(app)

    return app
