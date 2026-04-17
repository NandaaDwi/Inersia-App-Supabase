import 'package:flutter/material.dart';

class ReadCommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const ReadCommentInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFF1F2937),
        child: Icon(Icons.person_outline, color: Color(0xFF6B7280), size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan pendapatmu...',
                    hintStyle: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: onSend,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
            ],
          ),
        ),
      ),
    ],
  );
}
