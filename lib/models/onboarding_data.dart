import 'package:flutter/material.dart';

class OnboardingData {
  final String? title;
  final IconData? icon;
  final Color bgColor;
  final Color textColor;

  OnboardingData({
    this.title,
    this.icon,
    this.bgColor = Colors.white,
    this.textColor = Colors.black,
  });
}