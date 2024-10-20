import 'package:flutter/material.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key, required this.text, required this.color, required this.icon, this.secondColor = Colors.white, this.extraText = ''});

  final String text;
  final Color color;
  final IconData icon;
  final Color secondColor;
  final String extraText;

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.color,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (widget.extraText.isNotEmpty) Text(
              widget.extraText,
              style: TextStyle(
                fontSize: 28,
                color: widget.secondColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              widget.icon,
              size: 200,
              color: widget.secondColor,
            ),
            const SizedBox(height: 20),
            Text(
              widget.text,
              style: TextStyle(
                fontSize: 28,
                color: widget.secondColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
