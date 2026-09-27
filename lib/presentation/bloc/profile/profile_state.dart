import 'package:equatable/equatable.dart';
import 'package:klikin/domain/entities/click_profile.dart';

class ProfileState extends Equatable {
  final List<ClickProfile> profiles;
  final ClickProfile? activeProfile;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.profiles = const [],
    this.activeProfile,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isMaxSlotsReached => profiles.length >= 5;

  ProfileState copyWith({
    List<ClickProfile>? profiles,
    ClickProfile? activeProfile,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearActiveProfile = false,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      activeProfile:
          clearActiveProfile ? null : (activeProfile ?? this.activeProfile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        profiles,
        activeProfile,
        isLoading,
        errorMessage,
        successMessage,
      ];
}
