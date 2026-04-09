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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: state.value,
          dropdownColor: const Color(0xFF1E1E1E),
          isExpanded: true,
          decoration: InputDecoration(
            icon: Icon(icon, color: Colors.white54),
            border: InputBorder.none,
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e == 'admin'
                        ? 'Administrator'
                        : e == 'banned'
                        ? 'Diblokir'
                        : e == 'active'
                        ? 'Aktif'
                        : 'User Biasa',
                    style: TextStyle(
                      color: e == 'banned' ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => state.value = val!,
        ),
      ),
    );
  }
}
