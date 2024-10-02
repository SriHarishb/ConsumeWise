import 'dart:convert';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:consume_wise/AdminLogin.dart';
import 'package:consume_wise/CreateNew.dart';
import 'package:consume_wise/LoadingScreen.dart';
import 'package:consume_wise/ForgotPass.dart';
import 'package:consume_wise/History.dart';
import 'package:consume_wise/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';


void main() {
  

  runApp(const MyApp());
}

String enteredUsername = '';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/LoadingScreen',
      routes: {
        '/main': (context) => const LoginScreen(),
        '/ForgotPass':(context)=> const forgotPass(),
        '/Login' : (context)=> const CameraScreen(),
        '/CreateNew':(context)=> CreateNew(),
         '/History':(context)=>const History(responses: [],),
         '/AdminLogin':(context)=>const Adminlogin(),
         '/LoadingScreen':(context)=>LoadingScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Declare the users list, but initialize it later after loading the JSON
  List<Map<String, dynamic>> users = [];

Future<void> createUserDataFile() async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String path = '${appDocDir.path}/userData.json';
  File file = File(path);

  if (!await file.exists()) {
    // If it doesn't exist, create the file and write initial data
    const initialData = [
      {
        "username": "a",
        "password": "a",
        "diseases": {
          "diabetes": false,
          "hypertension": false,
          "asthma": false,
          "arthritis": false,
          "depression": false,
          "cancer": false,
          "heart_disease": false,
          "stroke": false,
          "obesity": false,
          "migraine": false
        }
      },
      {
        "username": "AD-a",
        "password": "ada",
        "diseases": {
          "diabetes": false,
          "hypertension": false,
          "asthma": false,
          "arthritis": false,
          "depression": false,
          "cancer": false,
          "heart_disease": false,
          "stroke": false,
          "obesity": false,
          "migraine": false
        }
      }
    ];

    // Write the initial data to the file
    await file.writeAsString(json.encode(initialData));
    print("User data file created and initialized successfully."); // Debug message
  } else {
    print("User data file already exists."); // Debug message
  }
}


  // Load the JSON data from the assets folder// Load the JSON data from the file system
Future<void> loadUserData() async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String path = '${appDocDir.path}/userData.json';
  
  // Check if the file exists
  if (await File(path).exists()) {
    String jsonString = await File(path).readAsString(); // Read the JSON file as a string
    List<dynamic> jsonData = json.decode(jsonString); // Decode JSON string to a List of dynamic objects

    setState(() {
      users = jsonData.cast<Map<String, dynamic>>(); // Cast the list to List<Map<String, dynamic>>
    });
        print("User data loaded successfully: $users[0]"); // Debug message

  } else {
    // Handle the case where the file does not exist
    print("User data file not found.");
  }
}



  // Check if the credentials are valid
  bool checkCredentials(String enteredUsername, String enteredPassword) {
    for (var user in users) {
      if (user['username'] == enteredUsername && user['password'] == enteredPassword) {
        return true; // Username and password match
      }
    }
    return false; // No match found
  }


@override
void initState() {
  super.initState();
  createUserDataFile().then((_) {
    loadUserData();
  });
}



  @override
  void dispose() {
    // Dispose controllers when no longer needed
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  // Function to handle login
  void _handleLogin() {
    enteredUsername = _usernameController.text;
    String enteredPassword = _passwordController.text;

    if (checkCredentials(enteredUsername, enteredPassword)) {
      // Navigate to another screen or show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful!")),
      );
      if (enteredUsername.startsWith('AD-')) {
      Navigator.pushNamed(context, '/AdminLogin');
      }
      else{
      Navigator.pushNamed(context, '/Login');
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Username or Password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -40,
                    height: 400,
                    width: width,
                    child: FadeInUp(duration: const Duration(seconds: 1), child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/background.png'),
                          fit: BoxFit.fill
                        )
                      ),
                    )),
                  ),
                  Positioned(
                    height: 400,
                    width: width+20,
                    child: FadeInUp(duration: const Duration(milliseconds: 1000), child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/background-2.png'),
                          fit: BoxFit.fill
                        )
                      ),
                    )),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(duration: const Duration(milliseconds: 1500), child: const Text("Login", style: TextStyle(color: Color.fromRGBO(251, 146, 255, 1), fontWeight: FontWeight.bold, fontSize: 30),)),
                  const SizedBox(height: 30,),
                  FadeInUp(duration: const Duration(milliseconds: 1700), child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      border: Border.all(color: const Color.fromRGBO(251, 146, 255, 1)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(111, 10, 114, 1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ]
                    ),
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(
                              color: Color.fromRGBO(196, 135, 198, .3)
                            ))
                          ),
                          child: TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Username",
                              hintStyle: TextStyle(color: Color.fromARGB(255, 52, 8, 59))
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Password",
                              hintStyle: TextStyle(color: Color.fromARGB(255, 52, 8, 59))
                            ),
                          ),
                        )
                      ],
                    ),
                  )),
                  const SizedBox(height: 20,),
                  FadeInUp(duration: const Duration(milliseconds: 1700), child: Center(child: TextButton(onPressed: () {Navigator.pushNamed(context, '/ForgotPass' );}, child: const Text("Forgot Password?", style: TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),)))),
                  const SizedBox(height: 30,),
                  FadeInUp(duration: const Duration(milliseconds: 1900), child: MaterialButton(
                    onPressed: _handleLogin,
                    color: const Color.fromRGBO(49, 39, 79, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    height: 50,
                    child: const Center(
                      child: Text("Login", style: TextStyle(color: Colors.white),),
                    ),
                  )),
                  const SizedBox(height: 30,),
                  FadeInUp(duration: const Duration(milliseconds: 2000), child: Center(child: TextButton(onPressed: () {Navigator.pushNamed(context, '/CreateNew');}, child: const Text("Create Account", style: TextStyle(color: Color.fromRGBO(251, 146, 255, 1)),)))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
