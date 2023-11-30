import 'package:flutter/material.dart';
import 'package:mrt_wallet/future/widgets/custom_widgets.dart';
import 'package:mrt_wallet/types/typedef.dart';

SnackBar createSnackAlert(
    {required String message,
    required DynamicVoid onTap,
    required ThemeData theme}) {
  final snackBar = SnackBar(
    backgroundColor: Colors.transparent,
    behavior: SnackBarBehavior.floating,
    actionOverflowThreshold: 0,
    elevation: 0,
    content: GestureDetector(
      onTap: onTap,
      child: Center(
        child: SizedBox(
          height: 60,
          width: 230,
          child: Center(
            child: Card(
              elevation: 3,
              child: Container(
                padding: WidgetConstant.padding10,
                decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: WidgetConstant.border8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: OneLineTextWidget(message),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return snackBar;
}
