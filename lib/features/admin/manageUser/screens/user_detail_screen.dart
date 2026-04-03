import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/models/user_model.dart';
import '../providers/admin_user_provider.dart';

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
        title: const Text("Profil Pengguna", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF161616),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1E1E),
                      border: Border.all(color: const Color(0xFF3F7AF6).withOpacity(0.5), width: 3),
                      image: user.photoUrl != null
                          ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: user.photoUrl == null
                        ? Center(
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white70, fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "@${user.username}",
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(user.followersCount, "Pengikut"),
                      Container(width: 1, height: 30, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 24)),
                      _buildStatItem(user.followingCount, "Mengikuti"),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("INFORMASI DASAR", style: TextStyle(color: Color(0xFF3F7AF6), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  _buildField("Nama Lengkap", nameController, Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildField("Username", usernameController, Icons.alternate_email),
                  const SizedBox(height: 16),
                  _buildField("Email", emailController, Icons.email),
                  const SizedBox(height: 16),
                  _buildField("Bio", bioController, Icons.notes, maxLines: 3),
                  const SizedBox(height: 24),
                  
                  const Text("PENGATURAN AKUN", style: TextStyle(color: Color(0xFF3F7AF6), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  _buildDropdown("Role Akses", selectedRole, ['user', 'admin'], Icons.admin_panel_settings_outlined),
                  const SizedBox(height: 16),
                  _buildDropdown("Status Akun", selectedStatus, ['active', 'banned'], Icons.gpp_maybe_outlined),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F7AF6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              isLoading.value = true;
                              try {
                                await ref.read(adminUserServiceProvider).updateUser(user.id, {
                                  'name': nameController.text,
                                  'username': usernameController.text,
                                  'bio': bioController.text,
                                  'role': selectedRole.value,
                                  'status': selectedStatus.value,
                                });
                                ref.invalidate(adminUsersProvider);
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.redAccent));
                              } finally {
                                isLoading.value = false;
                              }
                            },
                      child: isLoading.value
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    ),
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

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, ValueNotifier<String> state, List<String> items, IconData icon) {
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
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e == 'admin' ? 'Administrator' : e == 'banned' ? 'Diblokir' : e == 'active' ? 'Aktif' : 'User Biasa',
                      style: TextStyle(color: e == 'banned' ? Colors.redAccent : Colors.white),
                    ),
                  ))
              .toList(),
          onChanged: (val) => state.value = val!,
        ),
      ),
    );
  }
}