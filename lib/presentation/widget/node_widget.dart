import 'package:flutter/material.dart';
import 'package:graph_solver/core/extensions/colors_extensions.dart';

class CustomNodeWidget extends StatelessWidget {
  const CustomNodeWidget({
    required this.data,
    required this.color,
    super.key,
  });

  final String data;
  final Color color;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacityOnWhite(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        data,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}