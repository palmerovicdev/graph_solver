import 'package:flutter/material.dart';

class MethodButton extends StatelessWidget {
  const MethodButton({
    required this.label,
    required this.onPressed,
    required this.selected,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: selected ? Colors.white : Colors.blueGrey.shade700,
              backgroundColor: selected ? Colors.blueGrey.shade700 : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              side: BorderSide(
                color: selected ? Colors.blueGrey.shade700 : Colors.blueGrey.shade300,
              ),
            ),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
          ),
        ),
      ],
    );
  }
}