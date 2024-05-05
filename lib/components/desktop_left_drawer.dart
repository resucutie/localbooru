import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:localbooru/views/navigation/index.dart';

final alternativeRoutes = {
    "add": ["manage_image"],
    "settings": ["settings", "about"],
};

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
                        disableAddImage: alternativeRoutes["add"]!.contains(routeUri.pathSegments[0]),
                        disableSettings: alternativeRoutes["settings"]!.contains(routeUri.pathSegments[0]),
                        desktopView: true,
                        disableRecent: routeUri.path == "/search",
                    )
                ),
                // const SizedBox(width: 4),
                Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - (270 + 2), maxHeight: MediaQuery.of(context).size.height - 2),
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(28))
                    ),
                    child: child
                ),
            ],
        );
    }
}