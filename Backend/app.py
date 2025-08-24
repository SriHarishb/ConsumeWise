from flask import Flask
from config import Config
from app import init_app

app = init_app(Config)

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
