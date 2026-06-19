import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init();
  runApp(const LamecoApp());
}

class LamecoApp extends StatelessWidget {
  const LamecoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'لاميكو الاستثمارية-بيتا',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.dark(
          primary: AppColors.neonPurple,
          secondary: AppColors.neonCyan,
          surface: AppColors.bgCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgCard,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.bgCard,
          indicatorColor: AppColors.neonPurple.withValues(alpha: 0.2),
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
