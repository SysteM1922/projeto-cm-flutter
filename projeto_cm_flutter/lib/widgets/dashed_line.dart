import 'package:flutter/material.dart';

class DashedLine extends StatelessWidget {
  final double height;
  final double dashHeight;
  final Color color;

  const DashedLine({
    Key? key,
    this.height = 50,
    this.dashHeight = 5,
    this.color = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int dashCount = (height / (2 * dashHeight)).floor();
    return Container(
      height: height,
      width: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(dashCount, (_) {
          return SizedBox(
            height: dashHeight,
            child: Container(color: color),
          );
        }),
      ),
    );
  }
}
