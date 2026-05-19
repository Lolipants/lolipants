import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/router/app_router.dart';
import 'package:lolipants/core/theme/app_theme.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Root widget configuring theme and the go_router configuration.
class LolipantsApp extends ConsumerWidget {
  /// Creates the app shell.
  const LolipantsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(settingsLocaleProvider);
    final textScale = ref.watch(settingsTextScaleFactorProvider);
    final reduceMotion = ref.watch(settingsReduceMotionProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final content = child ?? const SizedBox.shrink();
        final wrapped = MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: mq.disableAnimations || reduceMotion,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ArabesqueBackground(
                opacity: ArabesqueBackground.defaultOpacity,
              ),
              content,
            ],
          ),
        );
        return wrapped;
      },
    );
  }
}
