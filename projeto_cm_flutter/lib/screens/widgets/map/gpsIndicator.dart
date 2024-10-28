import 'package:flutter/material.dart';

class GPSIcon extends StatelessWidget {
  const GPSIcon(
      {Key? key, required this.changeLocationOption, required this.gpsIcon})
      : super(key: key);

  final Function changeLocationOption;
  final Icon gpsIcon;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 10,
      child: ElevatedButton(
        onPressed: () {
          changeLocationOption();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.all(15),
        ),
        child: gpsIcon,
      ),
    );
  }
}
