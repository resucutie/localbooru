import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/image_manager/peripherals.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class DefaultDrawer extends StatelessWidget {
    const DefaultDrawer({super.key, this.activeView, this.displayTitle = true, this.desktopView = false});

    final bool displayTitle;
    final bool desktopView;
    final String? activeView;

    @override
    Widget build(context) {
        Color? assertSelected(String selectorView) {
            if(activeView == selectorView) return Theme.of(context).colorScheme.primary;
            return null;
        }
        return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
                SizedBox(height: MediaQuery.of(context).viewPadding.top),
                if(displayTitle) const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("LocalBooru",
                        style: TextStyle(
                            fontSize: 20.0
                        )
                    ),
                ),
                if(desktopView) ...[
                    ListTile(
                        textColor: assertSelected("home"),
                        iconColor: assertSelected("home"),
                        title: const Text("Home"),
                        leading: const Icon(Icons.home),
                        onTap: activeView != "home" ? () {
                            Scaffold.of(context).closeDrawer();
                            context.go("/home");
                        } : null,
                    ),
                    ListTile(
                        textColor: assertSelected("recent") ?? assertSelected("search"),
                        iconColor: assertSelected("recent") ?? assertSelected("search"),
                        title: const Text("Search"),
                        leading: const Icon(Icons.search),
                        onTap: activeView != "recent" && activeView != "search" ? () {
                            Scaffold.of(context).closeDrawer();
                            context.push("/recent");
                        } : null,
                    ),
                    const Divider(),
                ],
                ListTile(
                    textColor: assertSelected("manage_image"),
                    iconColor: assertSelected("manage_image"),
                    title: const Text("Add image"),
                    leading: const Icon(Icons.add),
                    onTap: activeView != "manage_image" ? () {
                        Scaffold.of(context).closeDrawer();
                        context.push("/manage_image");
                    } : null,
                ),
                ListTile(
                    title: const Text("Import from service"),
                    leading: const Icon(Icons.link),
                    enabled: activeView != "manage_image",
                    onTap: () {
                        Scaffold.of(context).closeDrawer();
                        showDialog(
                            context: context,
                            builder: (context) {
                                return const InsertURLDialog();
                            },
                        );
                    },
                ),
                ListTile(
                    textColor: assertSelected("settings"),
                    iconColor: assertSelected("settings"),
                    title: const Text("Settings"),
                    leading: const Icon(Icons.settings),
                    onTap: activeView != "settings" ? () {
                        Scaffold.of(context).closeDrawer();
                        context.push("/settings");
                    } : null,
                ),
                if(kDebugMode) ...[
                    const Divider(),
                    const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 16.0),
                        child: Text("Dev mode"),
                    ),
                    ListTile(
                        title: const Text("Playground"),
                        onTap: () {
                            Scaffold.of(context).closeDrawer();
                            context.push("/playground");
                        },
                    ),
                    ListTile(
                        title: const Text("Go to permissions screen"),
                        onTap: () {
                            Scaffold.of(context).closeDrawer();
                            context.push("/permissions");
                        },
                    ),
                    ListTile(
                        title: const Text("Go to biometric lock screen"),
                        onTap: () {
                            Scaffold.of(context).closeDrawer();
                            forceLockScreenListener.forceEnable();
                        },
                    ),
                    ListTile(
                        title: const Text("Toggle theme"),
                        onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final theme = prefs.getString("theme") ?? settingsDefaults["theme"];
                            if (theme == "dark") await prefs.setString("theme", "light");
                            else await prefs.setString("theme", "dark");
                            themeListener.update();
                        },
                    ),
                    ListTile(
                        title: const Text("Open picker"),
                        onTap: () async {
                            final stuff = await openSelectionDialog(context: context);
                            debugPrint("$stuff");
                        },
                    ),
                    ListTile(
                        title: const Text("Desktop size"),
                        onTap: () {
                            appWindow.size = const Size(1280, 720);
                        },
                    ),
                    ListTile(
                        title: const Text("Phone size"),
                        onTap: () {
                            appWindow.size = const Size(320, 840);
                        },
                    ),
                ]
            ],
        );
    }
}