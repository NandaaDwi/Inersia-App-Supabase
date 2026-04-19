import 'package:flutter/material.dart';

class EditorDiscardDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF161616),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text(
      'Keluar dari Editor?',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
    content: const Text(
      'Perubahan yang belum disimpan akan hilang.',
      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.5),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text(
          'Lanjut Edit',
          style: TextStyle(color: Color(0xFF9CA3AF)),
        ),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Keluar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
