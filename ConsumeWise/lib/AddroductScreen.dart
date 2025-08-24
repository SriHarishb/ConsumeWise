import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';

final gemini = GenerativeModel(
  model: "gemini-2.5-flash",
  apiKey: "",
);

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image1;
  File? _image2;
  File? _image3;
  bool _isLoading = false;
  String? _response;

  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _nutritionalInfoController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _healthSuggestionController = TextEditingController();

  Future<void> _pickImage(int imageNumber) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          if (imageNumber == 1) _image1 = File(pickedFile.path);
          else if (imageNumber == 2) _image2 = File(pickedFile.path);
          else if (imageNumber == 3) _image3 = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog("Error picking image: $e");
    }
  }

  Future<Uint8List> _compressImage(File image) async {
    final bytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) throw Exception("Cannot decode image");
    final resized = img.copyResize(decodedImage, width: 800);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  Future<void> _addProduct() async {
    if (_image1 == null || _image2 == null || _image3 == null) {
      _showErrorDialog('Please select all three images.');
      return;
    }
    if (_barcodeController.text.isEmpty || _productNameController.text.isEmpty) {
      _showErrorDialog('Please fill in at least Barcode Number and Product Name.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes1 = await _compressImage(_image1!);
      final bytes2 = await _compressImage(_image2!);
      final bytes3 = await _compressImage(_image3!);

      Map<String, String> productData = {
        'barcode_number': _barcodeController.text,
        'item_name': _productNameController.text,
        'brand': _brandNameController.text,
        'weight': _weightController.text,
        'ingredients': _ingredientsController.text,
        'nutritional_info': _nutritionalInfoController.text,
        'product_description': _productDescriptionController.text,
        'health_suggestion': _healthSuggestionController.text,
      };

      final url = Uri.parse('http://10.49.11.215:5000/products'); // Your API endpoint

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        _showErrorDialog('Product Added Successfully!');
        _clearForm();
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        String msg = body['message'] ?? 'Unknown reason';
        _showErrorDialog('Failed to add product: $msg');
      } else {
        _showErrorDialog('Failed to add product. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error adding product: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _barcodeController.clear();
    _productNameController.clear();
    _brandNameController.clear();
    _weightController.clear();
    _ingredientsController.clear();
    _nutritionalInfoController.clear();
    _productDescriptionController.clear();
    _healthSuggestionController.clear();
    setState(() {
      _image1 = null;
      _image2 = null;
      _image3 = null;
      _response = null;
    });
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notice'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );
      if (result != null) {
        setState(() {
          _barcodeController.text = result;
        });
      }
    } catch (e) {
      _showErrorDialog('Error opening barcode scanner: $e');
    }
  }

  Widget _imagePickerWidget(int index, File? image) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          color: theme.colorScheme.surfaceVariant,
          image: image != null ? DecorationImage(image: FileImage(image), fit: BoxFit.cover) : null,
        ),
        child: image == null
            ? Center(
                child: Text(
                  'Image $index',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.primary),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Select 3 Images of the Product',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _imagePickerWidget(1, _image1),
                _imagePickerWidget(2, _image2),
                _imagePickerWidget(3, _image3),
              ],
            ),
            const SizedBox(height: 30),
            _buildTextField('Barcode Number', _barcodeController),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.qr_code_scanner_rounded, color: theme.colorScheme.onPrimary),
                label: Text('Scan Barcode', style: TextStyle(color: theme.colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                ),
                onPressed: _scanBarcode,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Product Name', _productNameController),
            const SizedBox(height: 20),
            _buildTextField('Brand Name', _brandNameController),
            const SizedBox(height: 20),
            _buildTextField('Weight', _weightController),
            const SizedBox(height: 20),
            _buildTextField('Ingredients', _ingredientsController),
            const SizedBox(height: 20),
            _buildTextField('Nutritional Info', _nutritionalInfoController),
            const SizedBox(height: 20),
            _buildTextField('Product Description', _productDescriptionController),
            const SizedBox(height: 20),
            _buildTextField('Health Suggestion', _healthSuggestionController),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _addProduct,
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 3),
                      )
                    : Text(
                        'Add Product',
                        style: TextStyle(fontSize: 18, color: theme.colorScheme.onPrimary),
                      ),
              ),
            ),
            const SizedBox(height: 40),
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
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.error, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
