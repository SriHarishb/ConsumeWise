import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class CreateNew extends StatefulWidget {
  @override
  _CreateNewState createState() => _CreateNewState();
}

class _CreateNewState extends State<CreateNew> {
  // This boolean value will be used to control the switch.
  bool light1 = false;
  bool light2 = false;
  bool light3 = false;
  bool light4 = false;
  bool light5 = false;
  bool light6 = false;
  bool light7 = false;
  bool light8 = false;
  bool light9 = false;
  bool light10 = false;

  // Text controllers to get the input values
  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> _appendToJson() async {
    // Get the directory for the app
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.path}/userData.json';  
    
    // Ensure the directory exists
    if (!await Directory(appDocDir.path).exists()) {
      await Directory(appDocDir.path).create(recursive: true);
    }

    // Check if the file exists
    File file = File(filePath);
    Map<String, dynamic> userData = {
      "mail": emailController.text,
      "username": usernameController.text,
      "password": passwordController.text,
      "diseases": {
        "diabetes": light1,
        "hypertension": light2,
        "asthma": light3,
        "arthritis": light4,
        "depression": light5,
        "cancer": light6,
        "heart_disease": light7,
        "stroke": light8,
        "obesity": light9,
        "migraine": light10
      }
    };

    if (await file.exists()) {
      // Read existing data
      String jsonString = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(jsonString);

      // Append new data
      jsonData.add(userData);

      // Write back to file
      await file.writeAsString(jsonEncode(jsonData));
      
    } else {
      // If the file does not exist, create it with the user data
      List<dynamic> jsonData = [userData];
      await file.writeAsString(jsonEncode(jsonData));
    }
    Navigator.pushNamed(context, '/main');
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
                            fit: BoxFit.fill
                          )
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                    duration: const Duration(milliseconds: 1500),
                    child: const Text(
                      "Create Your Account",
                      style: TextStyle(
                        color: Color.fromRGBO(251, 146, 255, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1700),
                    child: Container(
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
                          // Email Field
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color.fromRGBO(196, 135, 198, .3)),
                              )
                            ),
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Mail",
                                hintStyle: TextStyle(color: Color.fromARGB(255, 52, 8, 59)),
                              ),
                            ),
                          ),
                          // Username Field
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Username",
                                hintStyle: TextStyle(color: Color.fromARGB(255, 52, 8, 59)),
                              ),
                            ),
                          ),
                          // Password Field
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Password",
                                hintStyle: TextStyle(color: Color.fromARGB(255, 52, 8, 59)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1700),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: const Text(
                              "Tell us more to Improve Your Experience",
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 85, 232),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Disease Switches
                        ..._buildDiseaseSwitches(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1900),
                    child: MaterialButton(
                      onPressed: _appendToJson,
                      color: const Color.fromRGBO(49, 39, 79, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      height: 50,
                      child: const Center(
                        child: Text(
                          "Create Account",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper method to build disease switches
  List<Widget> _buildDiseaseSwitches() {
    return [
      _buildSwitch("Diabetes", light1, (value) => setState(() => light1 = value)),
      _buildSwitch("Hypertension", light2, (value) => setState(() => light2 = value)),
      _buildSwitch("Asthma", light3, (value) => setState(() => light3 = value)),
      _buildSwitch("Arthritis", light4, (value) => setState(() => light4 = value)),
      _buildSwitch("Depression", light5, (value) => setState(() => light5 = value)),
      _buildSwitch("Cancer", light6, (value) => setState(() => light6 = value)),
      _buildSwitch("Heart Disease", light7, (value) => setState(() => light7 = value)),
      _buildSwitch("Stroke", light8, (value) => setState(() => light8 = value)),
      _buildSwitch("Obesity", light9, (value) => setState(() => light9 = value)),
      _buildSwitch("Migraine", light10, (value) => setState(() => light10 = value)),
    ];
  }

  // Method to create a single switch for diseases
  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color.fromARGB(255, 255, 0, 0),
          )
        ],
      ),
    );
  }
}
