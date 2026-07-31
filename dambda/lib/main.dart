import 'package:flutter/material.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DambdaApp());
}

class DambdaApp extends StatelessWidget {
  const DambdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAMBDA',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const MainShell(),
    );
  }
}
