import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/navigation/index.dart';

class DesktopHousing extends StatelessWidget {
    const DesktopHousing({super.key, required this.child, required this.routeUri});

    final Widget child;
    final Uri routeUri;

    @override
    Widget build(context) {
        return Row(
            children: [
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: DefaultDrawer(
                        displayTitle: false,
                        activeView: routeUri.pathSegments[0],
                        desktopView: true,
                    )
                ),
                // const SizedBox(width: 4),
                Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 270, maxHeight: MediaQuery.of(context).size.height - 2),
                    clipBehavior: isDesktop() ? Clip.antiAlias : Clip.none,
                    decoration: isDesktop() ? const BoxDecoration(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(28))
                    ) : null,
                    child: child
                ),
            ],
        );
    }
}