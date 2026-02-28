import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'pages/id_photo_home_page.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';

Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 锁定屏幕方向为竖屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

  // 初始化数据库
  await DatabaseService.init();

    runApp(
    const ProviderScope(
      child: MyApp(),
      ),
    );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '证件照处理',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: {
        AppThemeMode.system: ThemeMode.system,
        AppThemeMode.light: ThemeMode.light,
        AppThemeMode.dark: ThemeMode.dark,
      }[mode],
      home: const IdPhotoHomePage(),
    );
  }
}
