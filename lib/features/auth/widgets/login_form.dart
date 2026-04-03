import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:inersia_supabase/features/auth/screens/forgot_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginForm extends HookConsumerWidget {
  const LoginForm({super.key});

  String _mapAuthError(Object e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials'))
        return "Email atau password salah";
      if (msg.contains('email not confirmed'))
        return "Email belum diverifikasi. Silakan cek inbox Anda.";
      if (msg.contains('too many requests'))
        return "Terlalu banyak percobaan, coba lagi nanti";
      return e.message;
    }
    return "Terjadi kesalahan sistem";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useTextEditingController();
    final password = useTextEditingController();
    final obscure = useState(true);
    final state = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_mapAuthError(e)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Column(
      children: [
        _buildField(email, "Email", Icons.email_outlined),
        const SizedBox(height: 20),
        _buildField(
          password,
          "Password",
          Icons.lock_outline,
          isPassword: true,
          obscureText: obscure.value,
          onToggle: () => obscure.value = !obscure.value,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot-password'),
            child: const Text(
              "Lupa kata sandi?",
              style: TextStyle(color: Color(0xFF3F7AF6)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: state is AsyncLoading
                ? null
                : () => ref
                      .read(authProvider.notifier)
                      .login(email.text.trim(), password.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F7AF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
                    "Masuk",
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
                  obscureText!
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
