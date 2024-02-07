// Thanks to craftiplacer to provide with this widget!
// https://github.com/Kaiteki-Fedi/Kaiteki/blob/8190d6a2cbb106cebfd289fd917c0dd43e2d02dd/packages/kaiteki/lib/routing/router.dart#L528

import 'package:flutter/material.dart';

class DialogPage extends Page {
    const DialogPage({required this.builder, this.barrierColor, this.barrierDismissible = true, this.barrierLabel, this.useSafeArea = true, this.anchorPoint, this.traversalEdgeBehavior});
    
    final WidgetBuilder builder;
    final Color? barrierColor;
    final bool barrierDismissible;
    final String? barrierLabel;
    final bool useSafeArea;
    final Offset? anchorPoint;
    final TraversalEdgeBehavior? traversalEdgeBehavior;

    @override
    Route createRoute(BuildContext context) {
        return DialogRoute(
            builder: builder,
            context: context,
            settings: this,
            barrierColor: barrierColor ?? Colors.black54,
            anchorPoint: anchorPoint,
            barrierDismissible: barrierDismissible,
            barrierLabel: barrierLabel,
            traversalEdgeBehavior: traversalEdgeBehavior,
            useSafeArea: useSafeArea
        );
    }
}