import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:inersia_supabase/utils/auth_error_handler.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final state = ref.watch(authProvider);
    final countdown = useState(0);
    Timer? timer;

    void startTimer() {
      countdown.value = 60;
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (countdown.value == 0) {
          t.cancel();
        } else {
          countdown.value--;
        }
      });
    }

    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (prev is AsyncLoading) {
            context.push('/verify-otp', extra: emailController.text.trim());
          }
        },
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.map(e)),
            backgroundColor: Colors.redAccent,
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Lupa Kata Sandi",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Masukkan email untuk menerima kode OTP",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                hintText: "Email",
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (state is AsyncLoading || countdown.value > 0)
                    ? null
                    : () {
                        ref
                            .read(authProvider.notifier)
                            .forgotPassword(emailController.text.trim());
                        startTimer();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F7AF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state is AsyncLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        countdown.value > 0
                            ? "Tunggu ${countdown.value}s"
                            : "Kirim Kode OTP",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
