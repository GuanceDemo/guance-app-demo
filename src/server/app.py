import json
from pathlib import Path

from flask import Flask, request, jsonify, render_template, url_for
from ddtrace import tracer, patch
from flask_cors import CORS

patch(flask=True)

SERVER_VERSION = "1.1.0"
BUILD_DATE = "2026-04-16"
BASE_DIR = Path(__file__).resolve().parent
PRODUCTS_PATH = BASE_DIR / "data" / "products.json"

app = Flask(__name__)
CORS(app)


def load_products():
    with PRODUCTS_PATH.open("r", encoding="utf-8") as file:
        return json.load(file)


def serialize_product(product, include_details=True):
    item = dict(product)
    item["image_url"] = url_for("static", filename=item["image_path"], _external=True)
    item.pop("image_path", None)

    if not include_details:
        for key in ("description", "highlights", "specs", "web_points"):
            item.pop(key, None)

    return item


@app.after_request
def after_request(response):
    span = tracer.current_span()
    if span:
        response.headers["span_id"] = str(span.span_id)
        response.headers["trace_id"] = str(span.trace_id)
    return response


@app.route("/api/login", methods=["POST"])
def login():
    username = request.json.get("username")
    password = request.json.get("password")

    if username == "guance" and password == "admin":
        return jsonify({"success": True}), 200
    return jsonify({"error": "Invalid credentials"}), 401


@app.route("/api/user", methods=["GET"])
def get_user():
    host = request.host
    avatar_url = url_for("static", filename="images/demo-icon.png")
    return jsonify(
        {
            "username": "FakeUser",
            "email": "FakeEmail@example.com",
            "avatar": f"http://{host}{avatar_url}",
        }
    ), 200


@app.route("/connect", methods=["GET"])
def connect():
    return jsonify({"success": True}), 200


@app.route("/api/version", methods=["GET"])
def get_version():
    return jsonify(
        {
            "version": SERVER_VERSION,
            "build_date": BUILD_DATE,
            "service": "FT SDK Demo Server",
        }
    ), 200


@app.route("/api/products", methods=["GET"])
def get_products():
    products = [serialize_product(product, include_details=False) for product in load_products()]
    return jsonify(products), 200


@app.route("/api/products/<product_id>", methods=["GET"])
def get_product_detail(product_id):
    product = next((item for item in load_products() if item["id"] == product_id), None)
    if product is None:
        return jsonify({"error": "Product not found"}), 404
    return jsonify(serialize_product(product)), 200


@app.route("/")
def index():
    return render_template("index.html", name="GC_WebView")


@app.route("/product/<product_id>")
def product_detail(product_id):
    products = load_products()
    product = next((item for item in products if item["id"] == product_id), products[0])
    return render_template("product.html", product=serialize_product(product))


@app.route("/import_helper")
def import_helper():
    return render_template("import_helper.html", name="GC_Demo_Import_Heler")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
