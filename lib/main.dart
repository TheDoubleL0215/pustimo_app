import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:toastification/toastification.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';

const Color textColor = Color(0xFFE9EBF2);
const Color backgroundColor = Color(0xFF090B12);
const Color primaryColor = Color(0xFF99A5D6);
const Color secondaryColor = Color(0xFF293A81);
const Color accentColor = Color(0xFF3E59D0);
const Color text2Color = Color(0xFFAEB0B5);
const Color onBackgroundColor = Color(0xFF161B2C);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pustimo',
      builder: (context, child) {
        return ToastificationConfigProvider(
          config: ToastificationConfig(
            alignment: Alignment.topCenter,
            itemWidth: 440,
            animationDuration: Duration(milliseconds: 500),
            blockBackgroundInteraction: false,
          ),
          child: child!,
        );
      },
      theme: _buildTheme(),
      home: const AuthWrapper(),
    );
  }
}

ThemeData _buildTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryColor,
    onPrimary: backgroundColor,
    secondary: secondaryColor,
    onSecondary: textColor,
    surface: backgroundColor,
    onSurface: textColor,
    error: Colors.red.shade400,
    onError: Colors.white,
    tertiary: accentColor,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Outfit',
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: textColor, fontFamily: 'Outfit'),
      bodyMedium: TextStyle(color: textColor, fontFamily: 'Outfit'),
      bodySmall: TextStyle(color: text2Color, fontFamily: 'Outfit'),
      titleLarge: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontFamily: 'Outfit',
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: onBackgroundColor,
      foregroundColor: textColor,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: onBackgroundColor,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: secondaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: TextStyle(color: text2Color),
      hintStyle: TextStyle(color: text2Color),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
  );
}
