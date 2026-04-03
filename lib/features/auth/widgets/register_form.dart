import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:inersia_supabase/utils/auth_error_handler.dart';
import 'package:go_router/go_router.dart';

class RegisterForm extends HookConsumerWidget {
  const RegisterForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController();
    final username = useTextEditingController();
    final email = useTextEditingController();
    final password = useTextEditingController();
    final confirmPassword = useTextEditingController();

    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);

    final state = ref.watch(authProvider);

    return Column(
      children: [
        _buildField(name, "Nama Lengkap", Icons.person_outline),
        const SizedBox(height: 16),
        _buildField(username, "Username", Icons.alternate_email),
        const SizedBox(height: 16),
        _buildField(email, "Email", Icons.email_outlined),
        const SizedBox(height: 16),
        _buildField(
          password,
          "Password",
          Icons.lock_outline,
          isPassword: true,
          obscureText: obscurePassword.value,
          onToggle: () => obscurePassword.value = !obscurePassword.value,
        ),
        const SizedBox(height: 16),
        _buildField(
          confirmPassword,
          "Konfirmasi Password",
          Icons.lock_reset,
          isPassword: true,
          obscureText: obscureConfirm.value,
          onToggle: () => obscureConfirm.value = !obscureConfirm.value,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: state is AsyncLoading
                ? null
                : () async {
                    if (password.text != confirmPassword.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password tidak cocok"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    try {
                      await ref
                          .read(authProvider.notifier)
                          .register(
                            email.text.trim(),
                            password.text,
                            name.text,
                            username.text,
                          );
                      if (context.mounted) {
                        _showSuccessDialog(context);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AuthErrorHandler.mapError(e)),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F7AF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state is AsyncLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Daftar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Verifikasi Email",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Verifikasi email untuk menyelesaikan pembuatan akun.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/login'),
            child: const Text(
              "Ok",
              style: TextStyle(color: Color(0xFF3F7AF6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText ?? false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: Icon(icon, color: Colors.white54, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (obscureText ?? true)
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54,
                ),
                onPressed: onToggle,
              )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
