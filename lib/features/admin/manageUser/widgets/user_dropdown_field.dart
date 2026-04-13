import 'package:flutter/material.dart';

class UserDropdownField extends StatelessWidget {
  final String label;
  final ValueNotifier<String> state;
  final List<String> items;
  final IconData icon;

  const UserDropdownField({
    super.key,
    required this.label,
    required this.state,
    required this.items,
    required this.icon,
  });

  static const Map<String, String> _labels = {
    'admin': 'Administrator',
    'active': 'Aktif',
    'inactive': 'Nonaktif',
    'banned': 'Blokir  Permanen',
    'user': 'Pengguna Biasa',
  };

  static const Map<String, Color> _statusColors = {
    'admin': Colors.amber,
    'active': Colors.greenAccent,
    'inactive': Colors.orangeAccent,
    'banned': Colors.redAccent,
    'user': Colors.blueAccent,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: state.value,
          dropdownColor: const Color(0xFF252525),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          isExpanded: true,
          decoration: InputDecoration(
            icon: Icon(icon, color: Colors.white54, size: 22),
            border: InputBorder.none,
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          items: items.map((e) {
            final color = _statusColors[e] ?? Colors.white;
            return DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _labels[e] ?? 'Pengguna',
                    style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) state.value = val;
          },
        ),
      ),
    );
  }
}
