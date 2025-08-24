# ConsumeWise

ConsumeWise is a Public Information System designed to promote conscious consumption and encourage the production and mainstream adoption of healthy, sustainable products. The platform offers consumers verified data on food products, allowing them to make informed decisions based on nutritional value, sustainability, and ingredient suitability. The project emphasizes decentralized data evaluation and user-friendly interfaces tailored to consumers in India.


### Product Information: 

Get detailed data on food products, including nutritional values, ingredient lists, and more.

### Barcode Scanning: 

Quickly retrieve product information by scanning barcodes with the integrated scanner.
### Health Suggestions:

Personalized health suggestions based on the product's ingredients and the user's dietary preferences.

### Decentralized Data Evaluation: 

Encourage the production of verified healthy and sustainable products by providing a transparent evaluation system.

## Installation:

### Prerequisites:

Before you begin, ensure you have the following installed:

1. Flutter SDK
2. MongoDB for database setup
3. Dart (comes with Flutter)
4. python
5. Flask 

## Steps to Install:

1. Clone the repository:

```bash
git clone https://github.com/Sriharishb/Nutriscope.git
cd Nutriscope
```

2. Install dependencies:

```sh
flutter pub get
```


3. Set up MongoDB:

4. Run the server.py

```bash 
cd backend
pip install -r requirements.txt
python server.py
```


7. Build APK (optional): To generate APKs for specific ABIs:

```bash
flutter build apk --split-per-abi
```
## Usage:

### User:-

- Launch the app and use the barcode scanner to retrieve personalized health suggestion for product.
- Altenatively you can also get direct health suggestions by uploading the full product image.

### Administrator:- 
- Create User name starting with 'AD-' inorder to get admin access.
- Admin Can scan products, Decode Data Easily Using Gemini AI, Easily Correct the data if required.
- Then Send the data to the database for the users to access easily.

## Health Suggestions:

The app will provide health suggestions and identify any health risks associated with the product based on the user's health profile.
Based on user health profiles, the app offers personalized suggestions and warnings about ingredients that may pose health risks (e.g., allergens, sugars).

## API:

The Flutter backend exposes a REST API to interact with the MongoDB database.


## Technologies:

- Frontend: Flutter
- Backend: Flask (for API endpoints)
- Database: MongoDB
- Language: Dart,python
- Genai: Gemini

## Future Scope:

ConsumeWise has immense potential for future growth, with plans to expand its impact on promoting sustainable and healthy consumption. In the future, the platform aims to integrate advanced AI-powered tools to offer personalized recommendations based on user preferences, health conditions, and environmental impact. Enhanced data collection and verification mechanisms will provide more accurate assessments of product sustainability and nutritional value.

In the future, ConsumeWise will offer robust multilingual support to cater to a diverse user base across the globe. By integrating advanced natural language processing tools and translation services, the platform will provide seamless access to product information in multiple languages. This will include real-time translations for product descriptions, health suggestions, and sustainability insights, ensuring that users from various linguistic backgrounds can make informed choices in their preferred language. Additionally, voice recognition features will be enhanced to support queries and interactions in different languages, further improving accessibility and user experience.

## License:
This project is licensed under the MIT License. See the LICENSE file for details.

## Collaborators:

- Sri Harish : @SriHarishb

- Mohammed Saajid : @Mohammed-Saajid

- Arjun : @NSArjun

- Ashwina : @Ashwinakn


This README provides an organized and clear overview of your project, making it easy for others to understand and contribute to ConsumeWise. You can customize and expand the sections as your project evolves!