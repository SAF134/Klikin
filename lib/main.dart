import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:klikin/core/theme/app_theme.dart';
import 'package:klikin/data/repositories/profile_repository_impl.dart';
import 'package:klikin/domain/repositories/i_profile_repository.dart';
import 'package:klikin/presentation/bloc/permission/permission_bloc.dart';
import 'package:klikin/presentation/bloc/permission/permission_event.dart';
import 'package:klikin/presentation/bloc/profile/profile_bloc.dart';
import 'package:klikin/presentation/bloc/profile/profile_event.dart';
import 'package:klikin/presentation/bloc/service/service_bloc.dart';
import 'package:klikin/presentation/screens/splash_screen.dart';
import 'package:klikin/services/platform_bridge_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi storage lokal Hive
  await Hive.initFlutter();

  final bridgeService = PlatformBridgeService();
  final profileRepository = ProfileRepositoryImpl();

  runApp(KlikinApp(
    bridgeService: bridgeService,
    profileRepository: profileRepository,
  ));
}

class KlikinApp extends StatelessWidget {
  final PlatformBridgeService bridgeService;
  final IProfileRepository profileRepository;

  const KlikinApp({
    super.key,
    required this.bridgeService,
    required this.profileRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PlatformBridgeService>.value(value: bridgeService),
        RepositoryProvider<IProfileRepository>.value(value: profileRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PermissionBloc>(
            create: (context) => PermissionBloc(bridgeService: bridgeService)
              ..add(const CheckPermissionsEvent()),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(repository: profileRepository)
              ..add(const LoadProfilesEvent()),
          ),
          BlocProvider<ServiceBloc>(
            create: (context) => ServiceBloc(bridgeService: bridgeService),
          ),
        ],
        child: MaterialApp(
          title: 'Klikin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
