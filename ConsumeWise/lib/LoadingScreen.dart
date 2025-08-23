// ignore_for_file: library_private_types_in_public_api, file_names
import 'package:animate_do/animate_do.dart';
import 'package:consume_wise/main.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    startTimer();
  }

void startTimer() {
  Timer(const Duration(seconds: 5), () {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()), 
      (Route<dynamic> route) => false, 
    );
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 109, 0, 172),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 108, 23, 164), 
              Color.fromARGB(255, 56, 1, 32),
            ],
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 250,
            ),
            Container(
              height: 200,
              width: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/CLogo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(
              height: 80,
            ),
            FadeInUp(duration: const Duration(milliseconds: 2500), child: Text(
  "Scan Smart, Choose Healthy!",
  style: GoogleFonts.goudyBookletter1911(
    color: const Color.fromRGBO(255, 214, 246, 1),
    fontSize: 30,
    fontWeight: FontWeight.w300
  ),
)
,),
            const SizedBox(
              height: 80,
            ),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    ),);
  }
}
