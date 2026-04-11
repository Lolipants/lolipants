import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/router/app_router.dart';
import 'package:lolipants/core/theme/app_theme.dart';

/// Root widget configuring theme and the go_router configuration.
class LolipantsApp extends StatelessWidget {
  /// Creates the app shell.
  const LolipantsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
