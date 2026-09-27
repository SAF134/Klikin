import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klikin/domain/repositories/i_profile_repository.dart';
import 'package:klikin/presentation/bloc/profile/profile_event.dart';
import 'package:klikin/presentation/bloc/profile/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final IProfileRepository _repository;

  ProfileBloc({required IProfileRepository repository})
      : _repository = repository,
        super(const ProfileState(isLoading: true)) {
    on<LoadProfilesEvent>(_onLoadProfiles);
    on<SaveProfileEvent>(_onSaveProfile);
    on<DeleteProfileEvent>(_onDeleteProfile);
    on<SelectActiveProfileEvent>(_onSelectActiveProfile);
  }

  Future<void> _onLoadProfiles(
    LoadProfilesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final profiles = await _repository.getProfiles();
      emit(state.copyWith(
        profiles: profiles,
        activeProfile: state.activeProfile ?? (profiles.isNotEmpty ? profiles.first : null),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat profil: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSaveProfile(
    SaveProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.saveProfile(event.profile);
      final profiles = await _repository.getProfiles();
      emit(state.copyWith(
        profiles: profiles,
        activeProfile: event.profile,
        isLoading: false,
        successMessage: 'Profil "${event.profile.name}" berhasil disimpan.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e is StateError ? e.message : 'Gagal menyimpan profil: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteProfile(
    DeleteProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteProfile(event.id);
      final profiles = await _repository.getProfiles();
      final newActive = state.activeProfile?.id == event.id
          ? (profiles.isNotEmpty ? profiles.first : null)
          : state.activeProfile;

      emit(state.copyWith(
        profiles: profiles,
        activeProfile: newActive,
        clearActiveProfile: newActive == null,
        isLoading: false,
        successMessage: 'Profil berhasil dihapus.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus profil: ${e.toString()}',
      ));
    }
  }

  void _onSelectActiveProfile(
    SelectActiveProfileEvent event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(activeProfile: event.profile));
  }
}
