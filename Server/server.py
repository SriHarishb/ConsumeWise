from flask import Flask, jsonify, request
from pymongo import MongoClient
import google.generativeai as genai
from dotenv import load_dotenv
import os

load_dotenv()
genai.configure(api_key='')
mongo_uri = os.getenv("MONGODB_URI")
model = genai.GenerativeModel('gemini-2.5-flash')


app = Flask(__name__)

# Configure MongoDB connection
client = MongoClient(mongo_uri)  # Connect to the local MongoDB server
db = client['NutriScope']  # Replace with your database name
collection = db['products']  # Replace with your collection name

@app.route('/products', methods=['GET'])
def get_products():
    products = list(db.products.find({}, {'_id': 0}))  # Exclude _id field
    return jsonify(products)

@app.route('/products', methods=['POST'])
def add_product():
    print("im here")
    product = request.json  # Get the product data from the request
    barcode = product.get('barcode_number')  # Extract barcode from product data
    
    # Check if the product with the same barcode already exists
    existing_product = collection.find_one({"barcode": barcode})
    
    
    if existing_product:
        # If the product already exists, return a message indicating it's a duplicate
        return jsonify({"message": "Product with this barcode already exists!"}), 400
    else:
        # If the product does not exist, add it to the collection
        collection.insert_one(product)
        return jsonify({"message": "Product added successfully!"}), 201

# Route to get product information using barcode number
@app.route('/gethealthsuggestion', methods=['POST'])
def get_product_by_barcode():
    try:
        # Parse the barcode from the incoming JSON request
        data = request.get_json()
        print(request)
        barcode_number = data.get('barcode_number')
        diseases = data.get('diseases')



        # Query the database for the product with the given barcode number
        product = collection.find_one({"barcode_number": barcode_number}, {'_id': 0})  # Exclude _id field

        # If the product is found, return it as a JSON response
        if product:
            response = model.generate_content([f"These are the product details: {product}. The user have the following health concerns : {diseases}. Give health suggestions and advice for this specific product considering the health status of the user. Also consider the nutritional content and ingredients if provided and generate advice according to that.Do not include any punctuation marks other thatfull stop and comma."])

            return jsonify(response.text), 201
        else:
            print(f"{barcode_number}",product)
            return jsonify({"error": "Product not found"}), 400

    except Exception as e:
        return jsonify({"error": f"An error occurred: {str(e)}"}), 500




if __name__ == '__main__':
    app.run(host='0.0.0.0',debug=True)