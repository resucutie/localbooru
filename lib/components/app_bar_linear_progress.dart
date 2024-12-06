// Cant't use _kLinearProgressIndicatorHeight 'cause it is private in the
// progress_indicator.dart file
import 'package:flutter/material.dart';

const double _kMyLinearProgressIndicatorHeight = 6.0;

class AppBarLinearProgressIndicator extends LinearProgressIndicator implements PreferredSizeWidget {
    const AppBarLinearProgressIndicator({
        super.key,
        super.value,
        super.backgroundColor,
        super.valueColor,
        super.borderRadius,
        super.color,
        super.semanticsLabel,
        super.semanticsValue
    });

    @override
    final Size preferredSize = const Size(double.infinity, _kMyLinearProgressIndicatorHeight);
}