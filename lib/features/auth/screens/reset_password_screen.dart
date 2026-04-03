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
    final state = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (prev is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Kata sandi berhasil diperbarui! Silakan masuk kembali.",
                ),
                backgroundColor: Colors.green,
              ),
            );
            ref
                .read(authProvider.notifier)
                .logout()
                .then((_) => context.go('/login'));
          }
        },
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.mapError(e)),
            backgroundColor: Colors.redAccent,
          ),
        ),
      );
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
                passwordController,
                "Kata Sandi Baru",
                Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              _buildField(
                confirmController,
                "Konfirmasi Kata Sandi",
                Icons.lock_reset,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: state is AsyncLoading
                      ? null
                      : () {
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
                      ? const CircularProgressIndicator(color: Colors.white)
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

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        prefixIcon: Icon(icon, color: Colors.white54),
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
