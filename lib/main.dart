import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/localization/app_language_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_service.dart';
import 'features/auth/view/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await AppLanguageService().init();
  await AppThemeService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguageService().languageNotifier,
      builder: (context, lang, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeService().themeModeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              title: tr('app_title'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: const LoginScreen(),
            );
          },
        );
      },
    );
  }
}
