import 'package:animate_do/animate_do.dart';
import 'package:consume_wise/AddroductScreen.dart';
import 'package:consume_wise/auth_services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

List<String> responses = [];

final gemini = GenerativeModel(
  model: "gemini-1.5-flash",
  apiKey: "",
);

class CameraScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const CameraScreen({super.key, required this.userData});
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  bool _isLoading = false;
  String _response = '';
  String barcode = "";
  bool _isDarkMode = true;
  String username = "";
  Map<String, bool> userDiseases = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _initializeUserData();
  }

  void _initializeUserData() {
    final data = widget.userData;
    setState(() {
      username = (data['username'] ?? '') as String;
      userDiseases = (data['diseases'] != null) ? Map<String, bool>.from(data['diseases']) : {};
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? true;
      });
    }
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) {
        _showInfoDialog('No image was captured.');
        return;
      }
      setState(() {
        _images.add(File(photo.path));
      });
    } catch (e) {
      _showInfoDialog('Error capturing image: ${e.toString()}');
    }
  }

  Future<Uint8List> _compressImage(File image) async {
    final imageBytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) throw Exception("Could not decode image");
    final resized = img.copyResize(decodedImage, width: 800);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  Future<void> _submitImages() async {
    if (_images.isEmpty) {
      _showInfoDialog("Please add at least one image of the product.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dataParts = <DataPart>[];
      for (final image in _images) {
        final bytes = await _compressImage(image);
        dataParts.add(DataPart('image/jpeg', bytes));
      }
      final diseasesString = convertDiseasesToString(userDiseases);
      const promptTemplate =
          "Analyze the product in these images. The user has the following health profile: %s. Provide health advice and suggestions about this product for the user. Only use commas and periods for punctuation.";
      final prompt = promptTemplate.replaceAll('%s', diseasesString);
      final content = [Content.multi([TextPart(prompt), ...dataParts])];
      final response = await gemini.generateContent(content);
      setState(() {
        _response = response.text ?? 'No response from AI.';
        responses.add(_response);
      });
    } catch (e) {
      _showInfoDialog('Error analyzing images with AI. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );
      if (scannedCode != null && scannedCode.isNotEmpty) {
        if (!mounted) return;
        setState(() => barcode = scannedCode);
        await _sendBarCode(scannedCode);
      }
    } catch (e) {
      _showInfoDialog('Error opening scanner: $e');
    }
  }

  Future<void> _sendBarCode(String barcode) async {
    if (barcode.isEmpty) {
      _showInfoDialog("No barcode has been scanned yet.");
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final diseasesString = convertDiseasesToString(userDiseases);
      final healthData = {'barcode_number': barcode, 'diseases': diseasesString};
      final url = Uri.parse('http://10.49.11.215:5000/gethealthsuggestion');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        final text = response.body;
        if (text.isEmpty) {
          _showInfoDialog("Received empty response from server.");
        }
        setState(() {
          _response = text;
          responses.add(text);
        });
        _showInfoDialog('Health Suggestion Fetched Successfully!');
      } else if (response.statusCode == 400) {
        _showInfoDialog('This product is not in our database. Please use Submit Images option.');
      } else {
        _showInfoDialog('Failed to fetch suggestion. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showInfoDialog('An error occurred while fetching the product suggestion: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String convertDiseasesToString(Map<String, bool> diseases) {
    if (diseases.isEmpty) return "No health concerns listed.";
    return diseases.entries.where((e) => e.value).map((e) => e.key).join(', ');
  }

  void _showInfoDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attention'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authService.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('username');
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/main');
              },
              child: Text("Logout", style: TextStyle(color: Colors.red.shade400))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          _buildCameraPage(theme),
          History(responses: responses),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Camera"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              heroTag: "camera_fab",
              onPressed: _captureImage,
              shape: const CircleBorder(),
              child: const Icon(CupertinoIcons.camera_fill, size: 28),
            )
          : null,
    );
  }

  Widget _buildCameraPage(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $username', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') _handleLogout();
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                enabled: false,
                child: SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: _isDarkMode,
                  onChanged: _toggleTheme,
                  secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade400),
                  title: const Text("Logout"),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionCard(
  title: "Add A Product",
  child: Center(
    child: ElevatedButton.icon(
      icon: const Icon(Icons.add_box_outlined),
      label: const Text("Add Product"),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        );
      },
    ),
  ),
  action: const SizedBox.shrink(), // no extra button below because button is inside child
),

            const SizedBox(height: 28),
            _buildDivider(theme),
            const SizedBox(height: 28),
            _buildSectionCard(
              title: "Scan with Barcode",
              child: Text(
                barcode.isNotEmpty ? "Scanned: $barcode" : "No barcode scanned yet.",
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.75)),
              ),
              action: FilledButton.icon(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text("Scan Barcode"),
              ),
            ),
            const SizedBox(height: 28),
            if (_isLoading) const Center(child: CircularProgressIndicator()) else if (_response.isNotEmpty) _buildResponseCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, required Widget action}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 18),
          action,
        ]),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _images
          .map((img) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(img, width: 90, height: 90, fit: BoxFit.cover),
              ))
          .toList(),
    );
  }

  Widget _buildEmptyText(String message) {
    return Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium);
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text("OR", style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline)),
        ),
        Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildResponseCard(ThemeData theme) {
    return FadeInUp(
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Health Suggestion", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const Divider(height: 24),
            Text(_response, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ]),
        ),
      ),
    );
  }
}

class History extends StatelessWidget {
  final List<String> responses;
  const History({super.key, required this.responses});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: responses.isEmpty
          ? Center(child: Text("No history yet", style: theme.textTheme.bodyLarge))
          : ListView.builder(
              itemCount: responses.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(responses[index], style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                  ),
                );
              },
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
  bool _hasScanned = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (_hasScanned) return;
          final barcode = capture.barcodes.first.rawValue;
          if (barcode != null && mounted) {
            _hasScanned = true;
            Navigator.pop(context, barcode);
          }
        },
      ),
    );
  }
}
