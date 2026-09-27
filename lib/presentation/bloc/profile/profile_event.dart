import 'package:equatable/equatable.dart';
import 'package:klikin/domain/entities/click_profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfilesEvent extends ProfileEvent {
  const LoadProfilesEvent();
}

class SaveProfileEvent extends ProfileEvent {
  final ClickProfile profile;

  const SaveProfileEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DeleteProfileEvent extends ProfileEvent {
  final String id;

  const DeleteProfileEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SelectActiveProfileEvent extends ProfileEvent {
  final ClickProfile profile;

  const SelectActiveProfileEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}
