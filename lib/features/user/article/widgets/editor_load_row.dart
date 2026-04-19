import 'package:flutter/material.dart';

class LoadRow extends StatelessWidget {
  final String text;
  const LoadRow({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    ),
  );
}
