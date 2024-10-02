import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class forgotPass extends StatelessWidget {
  const forgotPass({super.key});

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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(duration: const Duration(milliseconds: 1500), child: const Text("Get Password Reset Link", style: TextStyle(color: Color.fromRGBO(251, 146, 255, 1), fontWeight: FontWeight.bold, fontSize: 30),)),
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
                          child: const TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter Your Mail",
                              hintStyle: TextStyle(color: Color.fromARGB(255, 52, 8, 59))
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 30,),
                  FadeInUp(duration: const Duration(milliseconds: 1900), child: MaterialButton(
                    onPressed: () {},
                    color: const Color.fromRGBO(49, 39, 79, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    height: 50,
                    child: const Center(
                      child: Text("Get Mail", style: TextStyle(color: Colors.white),),
                    ),
                  )),
                  ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
