import 'package:flutter/material.dart';

class History extends StatelessWidget {
  final List<String> responses;

  const History({super.key, required this.responses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 45, 18, 42),
      body: ListView.separated(
        itemCount: responses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              responses[index],
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const Divider(
            color: Colors.grey,
            thickness: 1,
            indent: 10,
            endIndent: 10,
          );
        },
      ),
    );
  }
}
