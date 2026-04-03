import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'category_management_screen.dart';
import 'tag_management_screen.dart';

class TaxonomyManagementScreen extends HookWidget {
  const TaxonomyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Konten Metadata",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: Colors.transparent,
                thumbColor: const Color(0xFF3F7AF6),
                groupValue: selectedIndex.value,
                children: {
                  0: _buildSegmentText("Kategori", selectedIndex.value == 0),
                  1: _buildSegmentText("Tag", selectedIndex.value == 1),
                },
                onValueChanged: (val) => selectedIndex.value = val!,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selectedIndex.value == 0
                  ? const CategoryManagementScreen()
                  : const TagManagementScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentText(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }
}
