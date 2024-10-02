import 'package:animate_do/animate_do.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart'; // Ensure this package is correctly configured
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
  List<File> _images = []; // List to store multiple images
  bool _isLoading = false;
  String _response = '';
  int _selectedIndex = 0;

  // Capture image and add to list
  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo == null) {
        _showErrorDialog('No image was captured. Please try again.');
        return;
      }

      setState(() {
        _images.add(File(photo.path)); // Add image to the list
      });
    } catch (e) {
      print('Error capturing image: $e');
      _showErrorDialog('Error capturing image: ${e.toString()}');
    }
  }

  // Compress the image before sending it
  Future<Uint8List> _compressImage(File image) async {
    // Load the image
    final imageBytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    // Resize the image to a maximum width/height of 800 pixels
    final resizedImage = img.copyResize(decodedImage!, width: 800);

    // Encode the image back to bytes with quality 85
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }
 bool imageGot=false;
  // Submit all captured images
  Future<void> _submitImages() async {
    setState(() {
      imageGot=true;
      _isLoading = true; // Start loading spinner
    });

    try {
      List<DataPart> dataParts = []; // Create a list for DataPart

      // Prepare the image data parts
      for (File image in _images) {
        Uint8List imageBytes = await _compressImage(image); // Compress the image
        dataParts.add(DataPart('image/jpeg', imageBytes)); // Add image bytes to the list
      }
      Map<String, bool> diseases = await getDiseases(Username);
  
      // Convert diseases to string
      String diseasesString = convertDiseasesToString(diseases);

      // Prepare the prompt
      String prompt = "Scan the images of this product. The user have the following health concerns : $diseasesString. Give health suggestions and advice for this product considering the health status of the user. Do not include any punctuation marks other than full stop and comma.";
      

      // Create content with prompt and all image data parts
      final content = [
        Content.multi([
          TextPart(prompt),
          ...dataParts // Add all image data parts here
        ])
      ];

      // Call the AI service with all images
      final responseText = await gemini.generateContent(content);

      setState(() {
        _response = responseText.text ?? 'No response from AI.';
        responses.add(_response); // Store response
      });



    } catch (e) {
      print('Error processing images: $e');
      _showErrorDialog('Error processing images with AI. Please try again.');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading spinner
      });
    }
  }

  // Show dialog with the image and AI response
  void _showImageResponseDialog(File image, String response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Picture Captured"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(image, height: 100, width: 100),
            const SizedBox(height: 10),
            Text("Response: $response"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String Barcode = "";

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        setState(() {
          Barcode = result.rawContent;
        });
      } else {
        _showErrorDialog('Barcode scan failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error scanning barcode: $e');
    }
  }

void _sendBarCode(String barcode) async {
   Map<String, bool> diseases = await getDiseases(Username);
  
      // Convert diseases to string
  String diseasesString = convertDiseasesToString(diseases);
  
  Map<String, String> healthdata = {
    'barcode_number': barcode,
    'diseases': diseasesString
  };
    
    // URL of the API endpoint
    final url = Uri.parse('FLASK-API-URL/gethealthsuggestion');  // Replace with your Flask API URL

    try {
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(healthdata),  // Convert the Map to a JSON string
      );

      // Check if the request was successful
      if (response.statusCode == 201) {
        _showErrorDialog('Health Suggestion Fetched!');
        setState(() {
        _response = response.body ;
        responses.add(_response); // Store response
      });

      } else if (response.statusCode == 400 ){
        _showErrorDialog('This Product is not in the database. Please upload the images of the full product using plus button below, and click Submit Images');
      }
      else {
        _showErrorDialog('Failed to Fetch Product suggestion. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or other errors
      _showErrorDialog('Error occurred while fetching the product suggestion: $e');
    }

  
}

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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

  Future<Map<String, bool>> getDiseases(String enteredUsername) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = '${appDocDir.path}/userData.json';
    String jsonString = await File(path).readAsString(); // Read the JSON file as a string
    List<dynamic> jsonData = json.decode(jsonString);
    // Find the user by username
    
   // Find the user by username
  Map<String, dynamic>? user = jsonData.firstWhere(
    (user) => user['username'] == enteredUsername,
    orElse: () => null,
  );

  // Return the diseases associated with the user, or an empty map if not found
  return user != null ? Map<String, bool>.from(user['diseases']) : {};
}

// Function to convert diseases map to a formatted string
String convertDiseasesToString(Map<String, bool> diseases) {
  List<String> diseaseList = [];

  diseases.forEach((key, value) {
    diseaseList.add('$key: ${value ? "Yes" : "No"}');
  });

  return diseaseList.join(', '); // Join all entries with a comma
}

  @override
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
          builder: (context) => History(responses: responses), // Pass responses here
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
          children: 
          <Widget>[
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
                  const Center(child: Text("Scan Your Product to get Started!",style: TextStyle(color: Color.fromRGBO(251, 146, 255, 1),fontWeight: FontWeight.w900,fontSize: 24),),),
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
                        style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Color.fromRGBO(125, 28, 128, 1))),
                          onPressed: _submitImages, // Submit all images
                          child: const Text("Submit Images",style: TextStyle(color: Colors.white),),
                        ),
                  const SizedBox(height: 20),
                  _response.isNotEmpty
                      ? Text(
                          imageGot == true ? _response : "" ,
                          style: const TextStyle(
                            color: Color.fromRGBO(252, 192, 254, 1),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 50),
                   const Center(child: Text("OR",style: TextStyle(color: Color.fromRGBO(254, 215, 255, 1),fontWeight: FontWeight.w900,fontSize: 24),),),
                  const SizedBox(height: 50),
                   const Center(child: Text("Scan Product Bar Code!",style: TextStyle(color: Color.fromRGBO(251, 146, 255, 1),fontWeight: FontWeight.w900,fontSize: 24),),),
                  const SizedBox(height: 40),

                  ElevatedButton(
                        style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Color.fromRGBO(125, 28, 128, 1))),
                        onPressed: _scanBarcode,
                        child: const Text("Scan Barcode",style: TextStyle(color: Colors.white),),
                        ),
                  const SizedBox(height: 20),
                  Text(
                          Barcode != "" ? Barcode : "Waiting For Barcode..." ,
                          style: const TextStyle(color: Color.fromRGBO(251, 146, 255, 1),fontWeight: FontWeight.w900,fontSize: 18)
                        ),     
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () => _sendBarCode(Barcode),style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Color.fromRGBO(125, 28, 128, 1))), child:const Text("Fetch Data",style: TextStyle(color: Colors.white),),),
                  const SizedBox(height: 20),
                  _response.isNotEmpty
                      ? Text(
                          Barcode != "" ? _response : "",
                          style: const TextStyle(
                            color: Color.fromRGBO(252, 192, 254, 1),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        )
                      : const SizedBox.shrink(),
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
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.file_copy_sharp),
                label: "Recents",
              ),
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
                  borderRadius: BorderRadius.circular(40),
                ),
                backgroundColor: const Color.fromRGBO(251, 146, 255, 1),
                onPressed: _captureImage, // Capture multiple images
                child: const Icon(CupertinoIcons.plus, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
