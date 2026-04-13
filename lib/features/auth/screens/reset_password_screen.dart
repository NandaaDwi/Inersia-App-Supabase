import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:inersia_supabase/utils/auth_error_handler.dart';

class ResetPasswordScreen extends HookConsumerWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();

    final obscurePassword = useState(true);
    final obscureConfirm = useState(true);

    final state = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (prev is AsyncLoading && next is AsyncData && next.value != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Kata sandi berhasil diperbarui! Silakan masuk kembali.",
            ),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(authProvider.notifier).logout().then((_) {
          if (context.mounted) context.go('/login');
        });
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.mapError(next.error)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reset Kata Sandi",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Masukkan kata sandi baru Anda.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildField(
                controller: passwordController,
                hint: "Kata Sandi Baru",
                icon: Icons.lock_outline,
                isObscure: obscurePassword.value,
                onToggle: () => obscurePassword.value = !obscurePassword.value,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: confirmController,
                hint: "Konfirmasi Kata Sandi",
                icon: Icons.lock_reset,
                isObscure: obscureConfirm.value,
                onToggle: () => obscureConfirm.value = !obscureConfirm.value,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: state is AsyncLoading
                      ? null
                      : () {
                          if (passwordController.text.isEmpty) return;
                          if (passwordController.text !=
                              confirmController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password tidak cocok"),
                              ),
                            );
                            return;
                          }
                          ref
                              .read(authProvider.notifier)
                              .resetPassword(passwordController.text.trim());
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
                          "Perbarui Kata Sandi",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: onToggle,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
