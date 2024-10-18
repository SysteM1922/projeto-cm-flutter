import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String code;
  final VoidCallback screenClosed;

  const ResultScreen({Key? key, required this.code, required this.screenClosed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Found Schedule"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            screenClosed();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Scanned Code:",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                code,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
