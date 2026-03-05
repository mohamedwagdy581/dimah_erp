import 'package:flutter/material.dart';

enum AppMsgType { success, error, info, warning }

class AppSnack {
  static void show(
    BuildContext context,
    String msg, {
    AppMsgType type = AppMsgType.info,
  }) {
    final color = switch (type) {
      AppMsgType.success => Colors.green,
      AppMsgType.error => Colors.red,
      AppMsgType.warning => Colors.orange,
      AppMsgType.info => Colors.blue,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
