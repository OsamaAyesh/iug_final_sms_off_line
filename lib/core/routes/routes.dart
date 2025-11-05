import 'package:app_mobile/features/splash_and_boarding/presentation/pages/on_boarding_screen.dart';
import 'package:app_mobile/features/splash_and_boarding/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../resources/manager_strings.dart';

/// A class defined for all routes constants
class Routes {
  static const String splash = '/splash';
  static const String onBoardingScreen = '/on_boarding_screen';
  static const String login = '/login';
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.onBoardingScreen:
        return MaterialPageRoute(builder: (_) => const OnBoardingScreen());
      default:
        return unDefinedRoute();
    }
  }

  /// If PushNamed Failed Return This Page With No Actions
  /// This Screen Will Tell The User This Page Is Not Exist
  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(
            ManagerStrings.noRouteFound,
          ),
        ),
        body: Center(
          child: Text(
            ManagerStrings.noRouteFound,
          ),
        ),
      ),
    );
  }
}
