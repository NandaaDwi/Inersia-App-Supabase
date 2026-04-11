import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/profile/services/profile_service.dart';

final profileServiceProvider = Provider.autoDispose((_) => ProfileService());

final profileDataProvider = FutureProvider.autoDispose<ProfileData>((ref) {
  return ref.read(profileServiceProvider).getProfile();
});
