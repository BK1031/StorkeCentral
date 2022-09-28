import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Color SB_NAVY = const Color(0xFF003660);
Color SB_GOLD = const Color(0xFFfebc11);

Color SB_LT_BLUE = const Color(0xFF0098ff);
Color SB_RED = const Color(0xFFf33535);
Color SB_AMBER = const Color(0xFFffca28);
Color SB_GREEN = const Color(0xFF00ca70);

List<Color> SB_COLORS = [SB_NAVY, SB_GOLD, SB_LT_BLUE, SB_RED, SB_AMBER, SB_GREEN];

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
    primary: SB_NAVY,
    secondary: SB_NAVY,
    onSecondary: Colors.white,
  ),
  fontFamily: "Product Sans",
  accentColor: SB_NAVY,
  primaryColor: SB_NAVY,
  backgroundColor: lightBackgroundColor,
  scaffoldBackgroundColor: lightBackgroundColor,
  cardColor: lightCardColor,
  cardTheme: CardTheme(
    color: lightCardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  listTileTheme: ListTileThemeData(
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
    primary: SB_NAVY,
    secondary: SB_NAVY,
  ),
  fontFamily: "Product Sans",
  accentColor: SB_NAVY,
  primaryColor: SB_NAVY,
  canvasColor: darkCanvasColor,
  backgroundColor: darkBackgroundColor,
  scaffoldBackgroundColor: darkBackgroundColor,
  cardColor: darkCardColor,
  cardTheme: CardTheme(
    color: darkCardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  listTileTheme: ListTileThemeData(
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