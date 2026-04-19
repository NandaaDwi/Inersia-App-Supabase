import 'package:flutter/material.dart';

class SuggestTile extends StatelessWidget {
  final String text;
  final bool isAction;
  const SuggestTile({required this.text, this.isAction = false});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF161616),
    child: ListTile(
      title: Text(
        text,
        style: TextStyle(
          color: isAction ? const Color(0xFF60A5FA) : Colors.white,
        ),
      ),
    ),
  );
}
