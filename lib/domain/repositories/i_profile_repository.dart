import 'package:klikin/domain/entities/click_profile.dart';

abstract class IProfileRepository {
  Future<List<ClickProfile>> getProfiles();
  Future<ClickProfile?> getProfileById(String id);
  Future<void> saveProfile(ClickProfile profile);
  Future<void> deleteProfile(String id);
}
