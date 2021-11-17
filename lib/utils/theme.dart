import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

bool darkMode = false;


Color sbNavy = const Color(0xFF003660);
Color sbGold = const Color(0xFFfebc11);

// LIGHT THEME
const lightTextColor = Colors.black;
const lightBackgroundColor = Color(0xFFf9f9f9);
const lightCardColor = Colors.white;
const lightDividerColor = Color(0xFFA8A8A8);

// Dark theme
const darkTextColor = Color(0xFFFFFFFF);
const darkBackgroundColor = Color(0xFF1F1F1F);
const darkCanvasColor = Color(0xFF242424);
const darkCardColor = Color(0xFF272727);
const darkDividerColor = Color(0xFF545454);

/// Light style
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light().copyWith(
    primary: sbNavy,
    secondary: sbNavy,
    onSecondary: Colors.white,
  ),
  accentColor: sbNavy,
  primaryColor: sbNavy,
  backgroundColor: lightBackgroundColor,
  scaffoldBackgroundColor: lightBackgroundColor,
  cardColor: lightCardColor,
  cardTheme: CardTheme(
    color: lightCardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
  ),
  dividerColor: lightDividerColor,
  dialogBackgroundColor: lightCardColor,
  // textTheme: GoogleFonts.openSansTextTheme(ThemeData.light().textTheme),
  popupMenuTheme: PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);

/// Dark style
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark().copyWith(
    primary: sbNavy,
    secondary: sbNavy,
  ),
  accentColor: sbNavy,
  primaryColor: sbNavy,
  canvasColor: darkCanvasColor,
  scaffoldBackgroundColor: darkBackgroundColor,
  cardColor: darkCardColor,
  cardTheme: CardTheme(
    color: darkCardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
  ),
  dividerColor: darkDividerColor,
  dialogBackgroundColor: darkCardColor,
  // textTheme: GoogleFonts.openSansTextTheme(ThemeData.dark().textTheme),
  popupMenuTheme: PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  ),
);