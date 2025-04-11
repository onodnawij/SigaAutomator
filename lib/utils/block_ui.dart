import 'package:flutter/material.dart';

void blockUI (BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // Prevent user interaction
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.white.withAlpha(0), // Dim color
          ),
        ],
      ),
    );
  }

  void unblockUI (BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }