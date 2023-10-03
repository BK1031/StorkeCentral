

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:storke_central/utils/theme.dart';

class AlertService {

  static showSuccessAlert() {

  }

  static showSuccessSnackbar(context, String message) {
    AnimatedSnackBar(
      mobileSnackBarPosition: MobileSnackBarPosition.bottom,
      desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
      builder: (context) {
        return Card(
          color: SB_GREEN,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const Padding(padding: EdgeInsets.all(4)),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white),)),
              ],
            ),
          ),
        );
      },
    ).show(context);
  }

  static showInfoSnackbar(context, String message) {
    AnimatedSnackBar(
      mobileSnackBarPosition: MobileSnackBarPosition.bottom,
      desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
      builder: (context) {
        return Card(
          color: SB_NAVY,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.info_rounded, color: Colors.white),
                const Padding(padding: EdgeInsets.all(4)),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white),)),
              ],
            ),
          ),
        );
      },
    ).show(context);
  }

  static showErrorSnackbar(context, String message) {
    AnimatedSnackBar(
      mobileSnackBarPosition: MobileSnackBarPosition.bottom,
      desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
      builder: (context) {
        return Card(
          color: SB_RED,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white),
                const Padding(padding: EdgeInsets.all(4)),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white),)),
              ],
            ),
          ),
        );
      },
    ).show(context);
  }

  static showConfirmationDialog(context, String title, String message, Function onConfirm) {
    CoolAlert.show(
      context: context,
      width: 300,
      type: CoolAlertType.warning,
      title: title,
      text: message,
      showCancelBtn: true,
      confirmBtnText: "YES",
      cancelBtnText: "CANCEL",
      confirmBtnColor: SB_NAVY,
      onConfirmBtnTap: () => onConfirm(),
      backgroundColor: SB_NAVY,
    );
  }

  static showWarningDialog(BuildContext context, String title, String message, Function onConfirm) {
    CoolAlert.show(
      context: context,
      width: 300,
      type: CoolAlertType.warning,
      title: title,
      text: message,
      confirmBtnText: "OK",
      confirmBtnColor: SB_NAVY,
      onConfirmBtnTap: () => onConfirm(),
      backgroundColor: SB_NAVY,
    );
  }

  static showErrorDialog(BuildContext context, String title, String message, Function onConfirm) {
    CoolAlert.show(
      context: context,
      width: 300,
      type: CoolAlertType.error,
      title: title,
      text: message,
      confirmBtnText: "OK",
      confirmBtnColor: SB_NAVY,
      onConfirmBtnTap: () => onConfirm(),
      backgroundColor: SB_NAVY,
    );
  }

  static showSuccessDialog(BuildContext context, String title, String message, Function onConfirm) {
    CoolAlert.show(
      context: context,
      width: 300,
      type: CoolAlertType.success,
      title: title,
      text: message,
      confirmBtnText: "OK",
      confirmBtnColor: SB_NAVY,
      onConfirmBtnTap: () => onConfirm(),
      backgroundColor: SB_NAVY,
    );
  }

}