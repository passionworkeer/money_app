import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'routes/app_router.dart';
import 'presentation/providers/settings_providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final themeMode = settingsAsync.maybeWhen(
      data: (settings) => settings.themeMode,
      orElse: () => ThemeMode.system,
    );
    final locale = settingsAsync.maybeWhen(
      data: (settings) => settings.locale,
      orElse: () => 'zh',
    );

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      locale: Locale(locale),
    );
  }
}
