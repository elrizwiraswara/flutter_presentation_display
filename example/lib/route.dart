import 'package:flutter/material.dart';
import 'package:flutter_presentation_display_example/main_screen.dart';
import 'package:flutter_presentation_display_example/presentation_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const MainScreen());
    case 'presentation':
      return MaterialPageRoute(builder: (_) => const PresentationScreen());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      );
  }
}
