// Thanks to craftiplacer to provide with this widget!
// https://github.com/Kaiteki-Fedi/Kaiteki/blob/8190d6a2cbb106cebfd289fd917c0dd43e2d02dd/packages/kaiteki/lib/routing/router.dart#L528

import 'package:flutter/material.dart';

class DialogPage extends Page {
    final WidgetBuilder builder;

    DialogPage({required this.builder, this.barrierColor, this.barrierDismissible = true, this.barrierLabel, this.useSafeArea = true, this.anchorPoint, this.traversalEdgeBehavior});

    Color? barrierColor = Colors.black54;
    bool barrierDismissible = true;
    String? barrierLabel;
    bool useSafeArea = true;
    Offset? anchorPoint;
    TraversalEdgeBehavior? traversalEdgeBehavior;

    @override
    Route createRoute(BuildContext context) {
        return DialogRoute(
            builder: (context) => Material(
                color: Colors.transparent,
                child: Builder(builder: builder)
            ),
            context: context,
            settings: this,
            barrierColor: barrierColor,
            anchorPoint: anchorPoint,
            barrierDismissible: barrierDismissible,
            barrierLabel: barrierLabel,
            traversalEdgeBehavior: traversalEdgeBehavior,
            useSafeArea: useSafeArea
        );
    }
}