import 'package:flutter/material.dart';

class SLabel extends StatelessWidget {
  final String label;

  const SLabel({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}