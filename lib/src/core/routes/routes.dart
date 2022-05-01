import 'package:flutter/material.dart';
import '../../views/screens/home/screens/home_screen.dart';

Route? routes(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) =>  const HomeScreen());
    default:
      return null;
  }
}
