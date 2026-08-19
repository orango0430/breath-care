import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved token before the first frame, so a returning user goes
  // straight to home instead of flashing the login screen on every launch.
  await ApiClient.instance.restoreSession();
  // Firebase has to be up before the first frame so a notification that
  // launched the app is still readable via getInitialMessage().
  await PushService.initialize();
  runApp(const BreathCareApp());
}

class BreathCareApp extends StatelessWidget {
  const BreathCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BPACE',
      debugShowCheckedModeBanner: false,
      // Cross-platform Scroll & Physics Unification
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: AppFonts.pretendard,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.lightMint,
          secondary: AppColors.coralRed,
          surface: AppColors.darkCharcoal,
          error: AppColors.coralRed,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        splashFactory: InkSparkle.splashFactory,
      ),
      home: const SplashScreen(),
    );
  }
}
