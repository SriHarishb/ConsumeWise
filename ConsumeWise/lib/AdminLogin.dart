import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data'; // For image compression
import 'package:mobile_scanner/mobile_scanner.dart'; // Using mobile_scanner
import 'package:image/image.dart' as img;
import 'dart:convert'; // For JSON parsing
import 'package:http/http.dart' as http;

final gemini = GenerativeModel(
  model: "gemini-2.5-flash",
  apiKey: "", 
);

class Adminlogin extends StatefulWidget {
  const Adminlogin({super.key});

  @override
  _AdminloginState createState() => _AdminloginState();
}

class _AdminloginState extends State<Adminlogin> {
  final ImagePicker _picker = ImagePicker();
  File? _image1;
  File? _image2;
  bool _isLoading = false;
  String? _response;
  String? barcode;
  String? productName;
  String? brandName;
  String? weight;
  String? ingredients;
  String? nutritionalInfo;
  String? productDescription;
  String? healthSuggestion;

  // Controllers for text fields
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _nutritionalInfoController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _healthSuggestionController = TextEditingController();
  final TextEditingController _aiResponseController = TextEditingController(); // For AI response

  // To handle the selected index for the bottom navigation bar
  int _selectedIndex = 0;

  // MODIFIED Barcode scanning function using mobile_scanner
  Future<void> _scanBarcode() async {
    try {
      // Navigate to the scanner screen and wait for a result.
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      // If a barcode was returned from the scanner screen, update the controller.
      if (result != null) {
        setState(() {
          _barcodeController.text = result;
        });
        print('Scanned Barcode: ${_barcodeController.text}');
      }
    } catch (e) {
      _showErrorDialog('Error opening scanner: $e');
    }
  }

  // Error dialog function
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notice'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  // Adding product
  void _addProduct() async {
    barcode = _barcodeController.text;
    productName = _productNameController.text;
    brandName = _brandNameController.text;
    weight = _weightController.text;
    ingredients = _ingredientsController.text;
    nutritionalInfo = _nutritionalInfoController.text;
    productDescription = _productDescriptionController.text;
    healthSuggestion = _healthSuggestionController.text;

    if (barcode!.isNotEmpty && productName!.isNotEmpty) {
      // Combine the values into a JSON object
      Map<String, String> productData = {
        'barcode_number': barcode!,
        'item_name': productName!,
        'brand': brandName!,
        'weight': weight!,
        'ingredients': ingredients!,
        'nutritional_info': nutritionalInfo!,
        'product_description': productDescription!,
        'health_suggestion': healthSuggestion!
      };

      // URL of the API endpoint
      final url = Uri.parse('http://10.49.11.215:5000/products'); // Replace with your Flask API URL

      try {
        // Send the POST request
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(productData), // Convert the Map to a JSON string
        );


        // Check if the request was successful
        if (response.statusCode == 201) {
          _showErrorDialog('Product Added Successfully!');
        } else if (response.statusCode == 400) {
          var responseBody = jsonDecode(response.body);
          String responseMsg = responseBody['message'];
          _showErrorDialog('Failed to add product. Because $responseMsg');
        } else {
          _showErrorDialog('Failed to add product. Status: ${response.statusCode}');
        }
      } catch (e) {
        // Handle network or other errors
        _showErrorDialog('Error occurred while adding the product: $e');
      }
    } else {
      _showErrorDialog('Please fill in all fields.');
    }
  }

  // Handling bottom navigation bar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Image picking function
  Future<void> _pickImage(int imageNumber) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        if (imageNumber == 1) {
          _image1 = File(pickedFile.path);
        } else {
          _image2 = File(pickedFile.path);
        }
      });
    }
  }

  // Compress image
  Future<Uint8List> _compressImage(File image) async {
    final imageBytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    final resizedImage = img.copyResize(decodedImage!, width: 800);
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  // Submit images and process AI response
  Future<void> _submitImages() async {
    if (_image1 == null || _image2 == null) {
      _showErrorDialog('Please select both images.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List imageBytes1 = await _compressImage(_image1!);
      Uint8List imageBytes2 = await _compressImage(_image2!);

      final dataParts = [
        DataPart('image/jpeg', imageBytes1),
        DataPart('image/jpeg', imageBytes2),
      ];

      String prompt =
          "Scan both images of the product.Return the product information as a JSON with the following keys: item_name, brand, barcode_number, weight, ingredients (a list), nutritional info (a dictionary), product_description, and health_suggestion. Generate the health_suggestion for the product. All the other keys should only be taken from the image.";

      final content = Content.multi([TextPart(prompt), ...dataParts]);

      final response = await gemini.generateContent([content]);

      setState(() {
        _response = response.text ?? 'No response from AI.';
        _aiResponseController.text = _response!;
        _populateFieldsFromResponse(_response!); // Populate text fields
      });
    } catch (e) {
      _showErrorDialog('Error processing images with AI: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Populate fields from AI response
  void _populateFieldsFromResponse(String response) {
    // Clean up the response by removing the JSON code blocks
    response = response.replaceAll("```", "").replaceAll("json", "").trim();

    try {
      // Attempt to parse the JSON response
      final dynamic jsonResponse = jsonDecode(response);

      // Check if the response is a list or a map
      if (jsonResponse is List) {
        // If it's a list, take the first element (if available) and cast it to a map
        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map) {
          _populateFieldsFromMap(Map<String, dynamic>.from(jsonResponse[0]));
        } else {
          _showErrorDialog('No product data found in the response.');
        }
      } else if (jsonResponse is Map) {
        // If it's a map, cast it and process it
        _populateFieldsFromMap(Map<String, dynamic>.from(jsonResponse));
      } else {
        _showErrorDialog('Unexpected AI response format.');
      }
    } catch (e) {
      _showErrorDialog('Error parsing AI response: $e');
    }
  }

  // Helper function to populate fields from a map
  void _populateFieldsFromMap(Map<String, dynamic> jsonResponse) {
    _productNameController.text = jsonResponse['item_name'] ?? '';
    _brandNameController.text = jsonResponse['brand'] ?? '';
    _barcodeController.text = jsonResponse['barcode_number'] ?? '';
    _weightController.text = jsonResponse['weight'] ?? '';
    _ingredientsController.text = (jsonResponse['ingredients'] as List<dynamic>?)?.join(', ') ?? '';
    _nutritionalInfoController.text = jsonResponse['nutritional_info']?.toString() ?? '';
    _productDescriptionController.text = jsonResponse['product_description'] ?? '';
    _healthSuggestionController.text = jsonResponse['health_suggestion'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black54,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 170,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 0,
                    height: 700,
                    width: width,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/main_bg.png'),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Enter Product Details",
                      style: TextStyle(
                          color: Color.fromRGBO(253, 186, 255, 1),
                          fontSize: 25,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(Color.fromRGBO(251, 146, 255, 1))),
                        onPressed: () => _pickImage(1),
                        child: const Text(
                          'Pick Image 1',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(Color.fromRGBO(251, 146, 255, 1))),
                        onPressed: () => _pickImage(2),
                        child: const Text(
                          'Pick Image 2',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 200, 79, 204))),
                    onPressed: _submitImages,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Submit Images',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 30),

                  // Button to trigger the barcode scanner
                  Center(
                    child: ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 200, 79, 204))),
                      onPressed: _scanBarcode,
                      child: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _productNameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _brandNameController,
                    decoration: const InputDecoration(
                      labelText: 'Brand Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _nutritionalInfoController,
                    decoration: const InputDecoration(
                      labelText: 'Nutritional Info',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _productDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Product Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),
                    controller: _healthSuggestionController,
                    decoration: const InputDecoration(
                      labelText: 'Health Suggestion',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 200, 79, 204))),
                    onPressed: _addProduct,
                    child: const Text(
                      'Add Product',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40), // Added padding at the bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: controller,
            // onDetect is called when a barcode is found
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  // Pop the screen and return the scanned code as the result
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          // This creates a visual guide for the user
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
