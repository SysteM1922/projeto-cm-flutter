import 'package:flutter/material.dart';
import 'package:projeto_cm_flutter/widgets/dashed_line.dart';


class StopIcon extends StatelessWidget {
  final bool isFirst;
  final bool isLast;

  const StopIcon({Key? key, required this.isFirst, required this.isLast})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, 
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isFirst)
            DashedLine(height: 15, dashHeight: 3, color: Colors.grey),
          const Icon(Icons.location_on, color: Colors.redAccent, size: 24),
          if (!isLast)
            DashedLine(height: 15, dashHeight: 3, color: Colors.grey),
        ],
      ),
    );
  }
}
