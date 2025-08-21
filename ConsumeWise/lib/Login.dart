import 'package:animate_do/animate_do.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'history.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'main.dart' as md;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

List<String> responses = [];

String Username = md.enteredUsername;

final gemini = GenerativeModel(
  model: "gemini-1.5-flash",
  apiKey: "", // Replace with your valid API key securely
);

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  bool _isLoading = false;
  String _response = '';
  int _selectedIndex = 0;
  bool imageGot = false;
  String Barcode = "";

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) {
        _showErrorDialog('No image was captured. Please try again.');
        return;
      }
      setState(() {
        _images.add(File(photo.path));
      });
    } catch (e) {
      print('Error capturing image: $e');
      _showErrorDialog('Error capturing image: ${e.toString()}');
    }
  }

  Future<Uint8List> _compressImage(File image) async {
    final imageBytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    final resizedImage = img.copyResize(decodedImage!, width: 800);
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  Future<void> _submitImages() async {
    setState(() {
      imageGot = true;
      _isLoading = true;
    });

    try {
      List<DataPart> dataParts = [];

      for (File image in _images) {
        Uint8List imageBytes = await _compressImage(image);
        dataParts.add(DataPart('image/jpeg', imageBytes));
      }

      Map<String, bool> diseases = await getDiseases(Username);
      String diseasesString = convertDiseasesToString(diseases);

      String prompt =
          "Scan the images of this product. The user have the following health concerns : $diseasesString. Give health suggestions and advice for this product considering the health status of the user. Do not include any punctuation marks other than full stop and comma.";

      final content = [
        Content.multi([
          TextPart(prompt),
          ...dataParts,
        ])
      ];

      final responseText = await gemini.generateContent(content);

      setState(() {
        _response = responseText.text ?? 'No response from AI.';
        responses.add(_response);
      });
    } catch (e) {
      print('Error processing images: $e');
      _showErrorDialog('Error processing images with AI. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // UPDATED barcode scanning function
  Future<void> _scanBarcode() async {
    try {
      // Navigate to the scanner screen and wait for a result.
      final scanned = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      // If a barcode was returned, update the state.
      if (scanned != null) {
        setState(() {
          Barcode = scanned;
        });
      } else {
        // Optionally, show a message if the user cancels.
        // _showErrorDialog('Barcode scan cancelled.');
      }
    } catch (e) {
      _showErrorDialog('Error opening scanner: $e');
    }
  }

  void _sendBarCode(String barcode) async {
    Map<String, bool> diseases = await getDiseases(Username);
    String diseasesString = convertDiseasesToString(diseases);

    Map<String, String> healthdata = {
      'barcode_number': barcode,
      'diseases': diseasesString
    };

    final url = Uri.parse('http://10.49.11.215:5000/gethealthsuggestion'); // Replace with your real URL

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthdata),
      );

      if (response.statusCode == 201) {
        _showErrorDialog('Health Suggestion Fetched!');
        setState(() {
          _response = response.body;
          responses.add(_response);
        });
      } else if (response.statusCode == 400) {
        _showErrorDialog(
            'This Product is not in the database. Please upload the images of the full product using plus button below, and click Submit Images');
      } else {
        _showErrorDialog(
            'Failed to Fetch Product suggestion. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog(
          'Error occurred while fetching the product suggestion: $e');
    }
  }

  Future<Map<String, bool>> getDiseases(String enteredUsername) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = '${appDocDir.path}/userData.json';
    String jsonString = await File(path).readAsString();
    List<dynamic> jsonData = json.decode(jsonString);

    Map<String, dynamic>? user = jsonData.firstWhere(
      (user) => user['username'] == enteredUsername,
      orElse: () => null,
    );

    return user != null ? Map<String, bool>.from(user['diseases']) : {};
  }

  String convertDiseasesToString(Map<String, bool> diseases) {
    List<String> diseaseList = [];

    diseases.forEach((key, value) {
      diseaseList.add('$key: ${value ? "Yes" : "No"}');
    });

    return diseaseList.join(', ');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/Login');
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => History(responses: responses),
        ),
      );
    }
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
                    child: FadeInUp(
                      duration: const Duration(seconds: 1),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/main_bg.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Scan Your Product to get Started!",
                    style: TextStyle(
                      color: Color.fromRGBO(251, 146, 255, 1),
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _images.isNotEmpty
                      ? Wrap(
                          spacing: 10,
                          children: _images
                              .map((image) => Image.file(image, height: 100, width: 100))
                              .toList(),
                        )
                      : const Text(
                          'No images captured',
                          style: TextStyle(
                            color: Color.fromRGBO(251, 146, 255, 0.638),
                          ),
                        ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: const ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                  Color.fromRGBO(125, 28, 128, 1))),
                          onPressed: _submitImages,
                          child: const Text("Submit Images", style: TextStyle(color: Colors.white)),
                        ),
                  const SizedBox(height: 20),
                  if (_response.isNotEmpty && imageGot)
                    Text(
                      _response,
                      style: const TextStyle(
                        color: Color.fromRGBO(252, 192, 254, 1),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  const SizedBox(height: 50),
                  const Text(
                    "OR",
                    style: TextStyle(
                      color: Color.fromRGBO(254, 215, 255, 1),
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    "Scan Product Bar Code!",
                    style: TextStyle(
                      color: Color.fromRGBO(251, 146, 255, 1),
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                            Color.fromRGBO(125, 28, 128, 1))),
                    onPressed: _scanBarcode,
                    child: const Text("Scan Barcode", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    Barcode.isNotEmpty ? Barcode : "Waiting For Barcode...",
                    style: const TextStyle(
                      color: Color.fromRGBO(251, 146, 255, 1),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _sendBarCode(Barcode),
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                            Color.fromRGBO(125, 28, 128, 1))),
                    child: const Text("Fetch Data", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  if (_response.isNotEmpty && Barcode.isNotEmpty)
                    Text(
                      _response,
                      style: const TextStyle(
                        color: Color.fromRGBO(252, 192, 254, 1),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Stack(
        children: [
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            iconSize: 35,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.file_copy_sharp), label: "Recents"),
            ],
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color.fromRGBO(49, 39, 79, 1),
          ),
          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: SizedBox(
              height: 69,
              width: 69,
              child: FloatingActionButton(
                heroTag: 'homeButton',
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
                backgroundColor: const Color.fromRGBO(251, 146, 255, 1),
                onPressed: _captureImage,
                child: const Icon(CupertinoIcons.plus, size: 30),
              ),
            ),
          ),
        ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black54,
      ),
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
                  // Pop the screen and return the scanned code as the result.
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          // This container creates a visual guide for the user.
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
