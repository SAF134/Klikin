import 'package:hive_flutter/hive_flutter.dart';
import 'package:klikin/data/datasources/secure_storage_helper.dart';
import 'package:klikin/data/models/click_profile_model.dart';
import 'package:klikin/domain/entities/click_profile.dart';
import 'package:klikin/domain/repositories/i_profile_repository.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  static const String boxName = 'klikin_profiles_box';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    final cipher = await SecureStorageHelper.getEncryptionCipher();
    _box = await Hive.openBox<String>(boxName, encryptionCipher: cipher);
    return _box!;
  }

  @override
  Future<List<ClickProfile>> getProfiles() async {
    final box = await _getBox();
    final profiles = <ClickProfile>[];

    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final model = ClickProfileModel.fromJson(jsonStr);
          profiles.add(model);
        } catch (_) {
          // Skip corrupt data
        }
      }
    }

    profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return profiles;
  }

  @override
  Future<ClickProfile?> getProfileById(String id) async {
    final box = await _getBox();
    final jsonStr = box.get(id);
    if (jsonStr == null) return null;
    return ClickProfileModel.fromJson(jsonStr);
  }

  @override
  Future<void> saveProfile(ClickProfile profile) async {
    final box = await _getBox();

    // Validasi batas maksimal 5 slot profil jika membuat baru
    if (!box.containsKey(profile.id) && box.length >= 5) {
      throw StateError('Batas maksimal 5 slot profil telah tercapai.');
    }

    final model = ClickProfileModel.fromEntity(profile);
    await box.put(profile.id, model.toJson());
  }

  @override
  Future<void> deleteProfile(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
