import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Color ACTIVE_ACCENT_COLOR = const Color(0xFF003660);

Color SC_PINK = const Color(0xFFCA84AE);
Color SC_PURPLE = const Color(0xFF9184B4);

Color SB_NAVY = const Color(0xFF003660);
Color SB_GOLD = const Color(0xFFfebc11);

Color SB_LT_BLUE = const Color(0xFF0098ff);
Color SB_RED = const Color(0xFFf33535);
Color SB_AMBER = const Color(0xFFffca28);
Color SB_GREEN = const Color(0xFF00ca70);

List<Color> SB_COLORS = [ACTIVE_ACCENT_COLOR, SB_GOLD, SB_LT_BLUE, SB_RED, SB_AMBER, SB_GREEN];

// MAPBOX
const MAPBOX_LIGHT_THEME = "mapbox://styles/bharat1031/clscx8i0f004901rbco9befg6";
const MAPBOX_DARK_THEME = "mapbox://styles/bharat1031/clscx3ehu00hr01r6dxv9fjam";

// LIGHT THEME
const lightTextColor = Color(0xFF000000);
const lightBackgroundColor = Color(0xFFf9f9f9);
const lightCardColor = Color(0xFFFFFFFF);
const lightDividerColor = Color(0xFFA8A8A8);

// Dark theme
const darkTextColor = Color(0xFFE9E9E9);
const darkBackgroundColor = Color(0xFF000000);
const darkCardColor = Color(0xFF0D0D0D);
const darkDividerColor = Color(0xFF545454);

/// Light style
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light().copyWith(
    primary: ACTIVE_ACCENT_COLOR,
    secondary: ACTIVE_ACCENT_COLOR,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    surface: Colors.transparent,
    background: lightBackgroundColor,
    surfaceTint: Colors.transparent,
  ),
  fontFamily: "Product Sans",
  primaryColor: ACTIVE_ACCENT_COLOR,
  scaffoldBackgroundColor: lightBackgroundColor,
  cardColor: lightCardColor,
  appBarTheme: AppBarTheme(
    foregroundColor: Colors.white,
    color: ACTIVE_ACCENT_COLOR,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
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
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: ACTIVE_ACCENT_COLOR,
    foregroundColor: Colors.white,
  ),
  dividerColor: lightDividerColor,
  dialogBackgroundColor: lightCardColor,
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
    primary: SC_PINK,
    secondary: SC_PINK,
    background: darkBackgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    surface: Colors.transparent,
    surfaceTint: Colors.transparent,
  ),
  fontFamily: "Product Sans",
  primaryColor: SC_PINK,
  scaffoldBackgroundColor: darkBackgroundColor,
  iconTheme: const IconThemeData(color: Colors.grey),
  cardColor: darkCardColor,
  appBarTheme: const AppBarTheme(
    foregroundColor: Colors.white,
    color: darkCardColor,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  cardTheme: CardTheme(
    color: darkCardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      // side: BorderSide(color: Colors.grey)
    ),
  ),
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    iconColor: Colors.grey,
  ),
  buttonTheme: ButtonThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: SC_PINK,
    foregroundColor: Colors.white,
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