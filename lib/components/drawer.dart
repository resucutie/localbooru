import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/dialogs/download_dialog.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/dialogs/textfield_dialogs.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

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
                if(desktopView) ListTile(
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
                    title: Text(desktopView ? "Search" : "Recents"),
                    leading: Icon(desktopView ? Icons.search : Icons.history),
                    onTap: activeView != "recent" && activeView != "search" ? () {
                        Scaffold.of(context).closeDrawer();
                        context.push("/recent");
                    } : null,
                ),
                ListTile(
                    textColor: assertSelected("collections"),
                    iconColor: assertSelected("collections"),
                    title: const Text("Collections"),
                    leading: const Icon(Icons.photo_library),
                    onTap: activeView != "collections" ? () {
                        Scaffold.of(context).closeDrawer();
                        context.push("/collections");
                    } : null,
                ),
                const Divider(),
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
                    onTap: () async {
                        final router = GoRouter.of(context);
                        final url = await showDialog<String>(
                            context: context,
                            builder: (context) {
                                return const InsertURLDialog();
                            },
                        );
                        if(url != null) {
                            importImageFromURL(url)
                                .then((preset) {
                                    router.push("/manage_image", extra: handleSendable(preset));
                                })
                                .onError((error, stack) {
                                    if(error.toString() == "Unknown file type" || error.toString() == "Not a URL") {
                                        Future.delayed(const Duration(milliseconds: 1)).then((value) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown service or invalid image URL inserted")));
                                        });
                                    } else {
                                        throw error!;
                                    }
                                }).whenComplete(() {
                                    Scaffold.of(context).closeDrawer();
                                });
                        }
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
                        title: const Text("progress bar collection import test"),
                        onTap: () {
                            VirtualPresetCollection.urlToPreset("https://e926.net/pools/42095");
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
                            lockListener.lock();
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
                            windowManager.setSize(const Size(1280, 720));
                            // appWindow.size = const Size(1280, 720);
                        },
                    ),
                    ListTile(
                        title: const Text("Phone size"),
                        onTap: () {
                            windowManager.setSize(const Size(320, 840));
                            // appWindow.size = const Size(320, 840);
                        },
                    )
                ]
            ],
        );
    }
}