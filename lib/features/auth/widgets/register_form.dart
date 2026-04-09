import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterForm extends HookConsumerWidget {
  const RegisterForm({super.key});

  String _mapError(Object e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists')) {
        return 'Email sudah terdaftar. Gunakan email lain.';
      }
      if (msg.contains('password should be')) {
        return 'Password minimal 6 karakter.';
      }
      return e.message;
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController();
    final usernameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();

    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);

    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (prev is AsyncLoading && next is AsyncData) {
        _showSuccessDialog(context);
      }
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapError(next.error)),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    return Column(
      children: [
        _buildField(
          controller: nameCtrl,
          hint: 'Nama Lengkap',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: usernameCtrl,
          hint: 'Username',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: emailCtrl,
          hint: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: passwordCtrl,
          hint: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscurePassword.value,
          onToggle: () => obscurePassword.value = !obscurePassword.value,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: confirmCtrl,
          hint: 'Konfirmasi Password',
          icon: Icons.lock_reset,
          isPassword: true,
          obscureText: obscureConfirm.value,
          onToggle: () => obscureConfirm.value = !obscureConfirm.value,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: authState is AsyncLoading
                ? null
                : () {
                    final name = nameCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final password = passwordCtrl.text;
                    final confirm = confirmCtrl.text;

                    if (name.isEmpty ||
                        username.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua field wajib diisi.'),
                          backgroundColor: Color(0xFFD97706),
                        ),
                      );
                      return;
                    }

                    if (password != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password tidak cocok.'),
                          backgroundColor: Color(0xFFD97706),
                        ),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password minimal 6 karakter.'),
                          backgroundColor: Color(0xFFD97706),
                        ),
                      );
                      return;
                    }

                    ref
                        .read(authProvider.notifier)
                        .register(email, password, name, username);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F7AF6),
              disabledBackgroundColor: const Color(0xFF374151),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: authState is AsyncLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Daftar',
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
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Verifikasi Email',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Kami telah mengirim email verifikasi. Silakan cek inbox kamu untuk menyelesaikan pendaftaran.',
          style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F7AF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ke halaman Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: Icon(icon, color: Colors.white54, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
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
