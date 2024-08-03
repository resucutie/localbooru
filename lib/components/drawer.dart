import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/dialogs/download_dialog.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/dialogs/textfield_dialogs.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class DesktopHousing extends StatefulWidget {
    const DesktopHousing({super.key, required this.child, required this.routeUri, this.roundedCorners = false});

    final Widget child;
    final Uri routeUri;
    final bool roundedCorners;

    @override
    State<DesktopHousing> createState() => _DesktopHousingState();
}

class _DesktopHousingState extends State<DesktopHousing> {
    double _importProgress = 0;

    @override
    void initState() {
        importListener.addListener(handleProgressDisplay);
        super.initState();
    }

    @override
    void dispose() {
        importListener.removeListener(handleProgressDisplay);
        super.dispose();
    }

    void handleProgressDisplay() {
        if(isDesktop()) setState(() => _importProgress = importListener.progress);
    }

    @override
    Widget build(context) {
        return Stack(
            children: [
                Row(
                    children: [
                        ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 270),
                            child: DefaultDrawer(
                                displayTitle: false,
                                activeView: widget.routeUri.pathSegments[0],
                                desktopView: true,
                            )
                        ),
                        // const SizedBox(width: 4),
                        Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 270, maxHeight: MediaQuery.of(context).size.height - 2),
                            clipBehavior: widget.roundedCorners ? Clip.antiAlias : Clip.none,
                            decoration: widget.roundedCorners ? const BoxDecoration(
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
                            ) : null,
                            child: widget.child
                        ),
                    ],
                ),
                if(importListener.isImporting && isDesktop()) Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(value: _importProgress,)
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
                        final url = await showDialog<String>(
                            context: context,
                            builder: (context) {
                                return const InsertURLDialog();
                            },
                        );
                        if(url != null) {
                            importImageFromURL(url)
                                .then((preset) {
                                    GoRouter.of(context).push("/manage_image", extra: PresetManageImageSendable(preset));
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