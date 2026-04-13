import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/models/user_model.dart';
import '../providers/admin_user_provider.dart';
import '../widgets/user_profile_header.dart';
import '../widgets/user_text_field.dart';
import '../widgets/user_dropdown_field.dart';
import '../widgets/user_save_button.dart';

class UserDetailScreen extends HookConsumerWidget {
  final UserModel user;
  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: user.name);
    final usernameController = useTextEditingController(text: user.username);
    final emailController = useTextEditingController(text: user.email);
    final bioController = useTextEditingController(text: user.bio ?? '');
    final selectedRole = useState(user.role);
    final selectedStatus = useState(user.status);
    final isLoading = useState(false);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          "Profil Pengguna",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            UserProfileHeader(user: user),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "INFORMASI DASAR",
                    style: TextStyle(
                      color: Color(0xFF3F7AF6),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  UserTextField(
                    label: "Nama Lengkap",
                    controller: nameController,
                    icon: Icons.person_outline,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  UserTextField(
                    label: "Username",
                    controller: usernameController,
                    icon: Icons.alternate_email,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  UserTextField(
                    label: "Email",
                    controller: emailController,
                    icon: Icons.email,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  UserTextField(
                    label: "Bio",
                    controller: bioController,
                    icon: Icons.notes,
                    maxLines: 3,
                    enabled: false,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "PENGATURAN AKUN",
                    style: TextStyle(
                      color: Color(0xFF3F7AF6),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  UserDropdownField(
                    label: "Role Akses",
                    state: selectedRole,
                    items: const ['user', 'admin'],
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  const SizedBox(height: 16),
                  UserDropdownField(
                    label: "Status Akun",
                    state: selectedStatus,
                    items: const ['active', 'inactive', 'banned'],
                    icon: Icons.gpp_maybe_outlined,
                  ),

                  const SizedBox(height: 40),
                  UserSaveButton(
                    isLoading: isLoading,
                    onPressed: () async {
                      isLoading.value = true;
                      try {
                        await ref
                            .read(adminUserServiceProvider)
                            .updateUser(user.id, {
                              'name': nameController.text,
                              'username': usernameController.text,
                              'bio': bioController.text,
                              'role': selectedRole.value,
                              'status': selectedStatus.value,
                            });
                        ref.invalidate(adminUsersProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Gagal update: $e"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } finally {
                        isLoading.value = false;
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
