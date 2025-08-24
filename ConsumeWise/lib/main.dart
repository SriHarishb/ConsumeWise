import 'package:animate_do/animate_do.dart';
import 'package:consume_wise/AddroductScreen.dart';
import 'package:consume_wise/CameraScreen.dart';
import 'package:consume_wise/CreateNew.dart';
import 'package:consume_wise/LoadingScreen.dart';
import 'package:consume_wise/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String enteredUsername = '';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    notifyListeners();
  }
}

final themeManager = ThemeManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeManager.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromRGBO(251, 146, 255, 1),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Consume Wise',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeManager.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/camera': (context) => const CameraScreen(userData: {}),
        '/createNew': (context) => const CreateNew(),
        '/addproductscreen': (context) => const AddProductScreen(),
        '/loading': (context) => const LoadingScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _isAdmin = false;
  Map<String, dynamic>? _userData;
  User? _user;

  @override
  void initState() {
    super.initState();
    _listenAuth();
  }

  void _listenAuth() {
    authService.authStateChanges.listen((user) async {
      if (user == null) {
        setState(() {
          _loading = false;
          _user = null;
          _userData = null;
          _isAdmin = false;
        });
        return;
      }

      final isAdmin = user.email?.startsWith('ad-') ?? false;
      Map<String, dynamic>? userData;

      // Check Firestore user doc
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        userData = userDoc.data();
      }

      setState(() {
        _loading = false;
        _user = user;
        _userData = userData;
        _isAdmin = isAdmin;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingScreen();
    }

    if (_user == null) {
      return const LoginScreen();
    }

    if (_isAdmin) {
      return const AddProductScreen();
    }

    if (_userData == null) {
      return CompleteProfileScreen(
        uid: _user!.uid,
        email: _user!.email ?? '',
        onProfileComplete: (userData) {
          setState(() {
            _userData = userData;
          });
        },
      );
    }

    return CameraScreen(userData: _userData!);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _showStatusMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await authService.signInWithGoogle();
      // No need to fetch Firestore here, AuthGate handles post-login flow
    } catch (e) {
      _showStatusMessage("Google Sign-In Failed: ${e.toString()}",
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 350,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -50,
                    height: 350,
                    width: width,
                    child: FadeInUp(
                      duration: const Duration(seconds: 1),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/background.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    height: 350,
                    width: width + 20,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/background-2.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: Text(
                      "Login",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    const SizedBox(height: 100),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1600),
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: theme.colorScheme.outline),
                          ),
                          icon: const Icon(Icons.login),
                          onPressed: _handleGoogleSignIn,
                          label: Text(
                            "Sign in with Google",
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CompleteProfileScreen extends StatefulWidget {
  final String uid;
  final String email;
  final Function(Map<String, dynamic>) onProfileComplete;

  const CompleteProfileScreen({
    required this.uid,
    required this.email,
    required this.onProfileComplete,
    super.key,
  });

  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool light1 = false,
      light2 = false,
      light3 = false,
      light4 = false,
      light5 = false,
      light6 = false,
      light7 = false,
      light8 = false,
      light9 = false,
      light10 = false;
  bool _isSaving = false;

  List<Widget> _buildDiseaseSwitches() {
    return [
      _buildSwitch("Diabetes", light1, (v) => setState(() => light1 = v)),
      _buildSwitch("Hypertension", light2, (v) => setState(() => light2 = v)),
      _buildSwitch("Asthma", light3, (v) => setState(() => light3 = v)),
      _buildSwitch("Arthritis", light4, (v) => setState(() => light4 = v)),
      _buildSwitch("Depression", light5, (v) => setState(() => light5 = v)),
      _buildSwitch("Cancer", light6, (v) => setState(() => light6 = v)),
      _buildSwitch("Heart Disease", light7, (v) => setState(() => light7 = v)),
      _buildSwitch("Stroke", light8, (v) => setState(() => light8 = v)),
      _buildSwitch("Obesity", light9, (v) => setState(() => light9 = v)),
      _buildSwitch("Migraine", light10, (v) => setState(() => light10 = v)),
    ];
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color.fromARGB(255, 255, 0, 0),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a username")));
      return;
    }

    setState(() => _isSaving = true);
    final diseases = {
      "Diabetes": light1,
      "Hypertension": light2,
      "Asthma": light3,
      "Arthritis": light4,
      "Depression": light5,
      "Cancer": light6,
      "Heart Disease": light7,
      "Stroke": light8,
      "Obesity": light9,
      "Migraine": light10,
    };

    final userData = {
      "uid": widget.uid,
      "email": widget.email,
      "username": username,
      "diseases": diseases,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .set(userData);
    setState(() => _isSaving = false);
    widget.onProfileComplete(userData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Profile")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 16),
            ..._buildDiseaseSwitches(),
            const SizedBox(height: 32),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text("Save & Continue"),
                  ),
          ],
        ),
      ),
    );
  }
}
