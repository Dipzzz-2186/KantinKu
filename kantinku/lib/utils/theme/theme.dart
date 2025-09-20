import 'package:flutter/material.dart';
import 'package:kantinku/utils/theme/custom_themes/text_theme.dart';

class TAppTheme {
    TAppTheme._();

    static ThemeData lightTheme = ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        textTheme: TTextTheme.lightTextTheme,
        scaffoldBackgroundColor: Colors.white
        
    );
    static ThemeData darkTheme = ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        textTheme: TTextTheme.darkTextTheme,
        scaffoldBackgroundColor: Colors.white
    );
}