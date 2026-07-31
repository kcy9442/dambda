import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'state/auth_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 저장된 토큰이 있으면 재로그인 없이 세션 복구 시도 (네이티브 실행 시 기본 런치 스크린이
  // 이 짧은 대기 구간을 덮어줌)
  await authState.tryRestoreSession();
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
      home: ListenableBuilder(
        listenable: authState,
        builder: (context, _) {
          return authState.isLoggedIn ? const MainShell() : const LoginScreen();
        },
      ),
    );
  }
}
