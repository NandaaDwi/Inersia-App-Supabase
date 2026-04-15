import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:inersia_supabase/utils/auth_error_handler.dart';

class RegisterForm extends HookConsumerWidget {
  const RegisterForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController();
    final usernameCtrl = useTextEditingController();
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);
    final isPolicyAccepted = useState(false);
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (prev is AsyncLoading && next is AsyncData) {
        _showSuccessDialog(context);
      }
      if (next is AsyncError) {
        _showError(context, AuthErrorHandler.mapRegister(next.error));
      }
    });

    return Column(
      children: [
        _RegField(
          controller: nameCtrl,
          hint: 'Nama Lengkap',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _RegField(
          controller: usernameCtrl,
          hint: 'Username (huruf, angka, underscore)',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),
        _RegField(
          controller: emailCtrl,
          hint: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _RegField(
          controller: passwordCtrl,
          hint: 'Kata Sandi (min. 8 karakter)',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: obscurePassword.value,
          onToggle: () => obscurePassword.value = !obscurePassword.value,
        ),
        const SizedBox(height: 16),
        _RegField(
          controller: confirmCtrl,
          hint: 'Konfirmasi Kata Sandi',
          icon: Icons.lock_reset,
          isPassword: true,
          obscureText: obscureConfirm.value,
          onToggle: () => obscureConfirm.value = !obscureConfirm.value,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: isPolicyAccepted.value,
                onChanged: (v) => isPolicyAccepted.value = v ?? false,
                activeColor: const Color(0xFF3F7AF6),
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => isPolicyAccepted.value = !isPolicyAccepted.value,
                child: const Text.rich(
                  TextSpan(
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    children: [
                      TextSpan(text: 'Saya setuju dengan '),
                      TextSpan(
                        text: 'Kebijakan Privasi',
                        style: TextStyle(
                          color: Color(0xFF3F7AF6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' yang berlaku.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: authState is AsyncLoading
                ? null
                : () => _onRegister(
                    context: context,
                    ref: ref,
                    name: nameCtrl.text.trim(),
                    username: usernameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passwordCtrl.text,
                    confirm: confirmCtrl.text,
                    policyAccepted: isPolicyAccepted.value,
                  ),
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

  void _onRegister({
    required BuildContext context,
    required WidgetRef ref,
    required String name,
    required String username,
    required String email,
    required String password,
    required String confirm,
    required bool policyAccepted,
  }) {
    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      _showWarning(context, 'Semua field wajib diisi.');
      return;
    }
    if (name.length < 2) {
      _showWarning(context, 'Nama terlalu pendek. Minimal 2 karakter.');
      return;
    }
    if (username.length < 3) {
      _showWarning(context, 'Username terlalu pendek. Minimal 3 karakter.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      _showWarning(
        context,
        'Username hanya boleh berisi huruf, angka, dan underscore (_).',
      );
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showWarning(context, 'Format email tidak valid.');
      return;
    }
    if (password.length < 8) {
      _showWarning(context, 'Kata sandi terlalu pendek. Minimal 8 karakter.');
      return;
    }
    if (password != confirm) {
      _showWarning(context, 'Konfirmasi kata sandi tidak cocok.');
      return;
    }
    if (!policyAccepted) {
      _showWarning(context, 'Kamu harus menyetujui Kebijakan Privasi.');
      return;
    }

    ref.read(authProvider.notifier).register(email, password, name, username);
  }

  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.mark_email_read_rounded,
              color: Color(0xFF059669),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Verifikasi Email',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Kami telah mengirim email verifikasi ke alamat yang kamu daftarkan.\n\n'
          'Silakan buka inbox, lalu klik link verifikasi untuk mengaktifkan akun.',
          style: TextStyle(color: Color(0xFF9CA3AF), height: 1.6),
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
              'Ke Halaman Masuk',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void _showWarning(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _RegField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggle;
  final TextInputType? keyboardType;

  const _RegField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggle,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
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
