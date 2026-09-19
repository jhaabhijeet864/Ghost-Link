import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LocalLoopApp(),
    ),
  );
}

class LocalLoopApp extends ConsumerWidget {
  const LocalLoopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    const obsidianBg = Color(0xFF090A0C);
    const gunmetalSurface = Color(0xFF121418);
    const titaniumBorder = Color(0xFF2A2E39);
    const coolSteelGray = Color(0xFF8A94A6);

    return MaterialApp.router(
      title: 'LocalLoop',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: obsidianBg,
        canvasColor: gunmetalSurface,
        cardColor: gunmetalSurface,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: obsidianBg,
          secondary: coolSteelGray,
          onSecondary: obsidianBg,
          surface: gunmetalSurface,
          onSurface: Colors.white,
          error: Color(0xFFFF3D00),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: obsidianBg,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: gunmetalSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: titaniumBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: gunmetalSurface,
          hintStyle: const TextStyle(color: coolSteelGray),
          labelStyle: const TextStyle(color: coolSteelGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: titaniumBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: titaniumBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: gunmetalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: titaniumBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: obsidianBg,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: titaniumBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: titaniumBorder,
          thickness: 1,
        ),
      ),
      routerConfig: router,
    );
  }
}
