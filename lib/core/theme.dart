import 'package:flutter/material.dart';

const kMint = Color(0xFF5ECFB1);

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: kMint,
    fontFamily: 'SF Pro Display',
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
