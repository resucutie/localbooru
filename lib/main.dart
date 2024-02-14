import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/dialog_page.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:localbooru/utils/update_checker.dart';
import 'package:localbooru/views/image_manager.dart';
import 'package:localbooru/views/navigation/home.dart';
import 'package:localbooru/views/navigation/image_view.dart';
import 'package:localbooru/views/navigation/index.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';
import 'package:localbooru/views/set_booru.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/settings/index.dart';
import 'package:localbooru/views/settings/overallSettings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import 'package:localbooru/views/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> hasExternalStoragePerms() async{
    if (isMobile()) return await Permission.manageExternalStorage.status.isGranted;
    return true;
}

final _router = GoRouter(
    initialLocation: '/home',
    routes: [
        GoRoute(path: '/',
            redirect: (context, GoRouterState state) async {
                final hasPerms = await hasExternalStoragePerms();
                final prefs = await SharedPreferences.getInstance();
                
                if (!hasPerms) return "/permissions";
                if (prefs.getString("booruPath") == null) return "/setbooru";

                return null;
            },
            routes: [
                // navigation
                ShellRoute(
                    builder: (context, state, child) => BrowseScreen(uri: state.uri, child: child),
                    routes: [
                        GoRoute(path: "home",
                            builder: (context, state) => const HomePage(),
                        ),
                        GoRoute(path: "search",
                            builder: (context, state) {
                                final String tags = Uri.decodeFull(state.uri.queryParameters["tag"] ?? "");
                                final String? index = state.uri.queryParameters["index"];
                                return BooruLoader(
                                    builder: (context, booru) => GalleryViewer(
                                        booru: booru,
                                        tags: tags,
                                        index: int.parse(index ?? "0"),
                                        routeNavigation: true,
                                    ),
                                );
                            }
                        ),
                        GoRoute(path: "recent", redirect: (_, __) => '/search',),
                        GoRoute(path: "view/:id",
                            builder: (context, state)  {
                                final String? id = state.pathParameters["id"];
                                if (id == null) return Text("Invalid ID $id");
                                return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                    booru: booru,
                                    id: id,
                                    builder: (context, image) {
                                        return ImageView(image: image);
                                    }
                                ));
                            }
                        ),
                    ]
                ),

                // dialogs
                GoRoute(path: "dialogs",
                    redirect: (context, state) => null,
                    routes: [
                        GoRoute(path: "zoom_image/:id",
                            pageBuilder: (context, state) {
                                final String? id = state.pathParameters["id"];
                                if (id == null) return DialogPage(builder: (_) => Text("Invalid ID $id"));
                                return DialogPage(
                                    barrierColor: Colors.black,
                                    builder: (context) => BooruLoader(builder: (_, booru) => BooruImageLoader(
                                        booru: booru,
                                        id: id,
                                        builder: (context, image) => ImageViewZoom(image),
                                    ))
                                );
                            }
                        ),
                        // GoRoute(path: "delete_image_confirmation/:id",
                        //     pageBuilder: (context, state) {
                        //         final String? id = state.pathParameters["id"];
                        //         if (id == null) return DialogPage(builder: (_) => Text("Invalid ID $id"));
                        //         return DialogPage(
                        //             builder: (context) => DeleteImageDialogue(id: id,)
                        //         );
                        //     }
                        // ),
                        // GoRoute(path: "update",
                        //     pageBuilder: (context, state) {
                        //         final String ver = state.uri.queryParameters["ver"] ?? "";
                        //         return DialogPage(builder: (context) => AlertDialog(
                        //             title: const Text("Update avaiable"),
                        //             content: Text("A new version is avaiable for download: $ver. Update now?"),
                        //             actions: [
                        //                 TextButton(onPressed: context.pop, child: const Text("Later")),
                        //                 TextButton(child: const Text("Yes"), 
                        //                     onPressed: () {
                        //                         launchUrlString("https://github.com/resucutie/localbooru/releases/tag/$ver");
                        //                         context.pop();
                        //                     }
                        //                 ),
                        //             ],
                        //         ));
                        //     },
                        // )
                    ]
                ),

                // image add
                GoRoute(path: "manage_image",
                    builder: (context, state) {
                        return const ImageManagerView();
                    },
                    routes: [
                        GoRoute(path: ":id",
                            builder: (context, state) {
                                debugPrint("mow");
                                final String? id = state.pathParameters["id"];
                                if(id == null || int.tryParse(id) == null) return const Text("Invalid route");
                                return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                    booru: booru,
                                    id: id,
                                    builder: (context, image) {
                                        return ImageManagerView(
                                            image: image,
                                        );
                                    }
                                ));
                            },
                        )
                    ]
                ),

                // settings
                ShellRoute(
                    builder: (context, state, child) => SettingsShell(child: child),
                    routes: [
                        GoRoute(path: "settings",
                            builder: (context, state) => const SettingsHome(),
                            routes: [
                                GoRoute(path: "overall_settings",
                                    builder: (context, state) => SharedPreferencesBuilder(builder: (context, prefs) => OverallSettings(prefs: prefs)),
                                )
                            ]
                        )
                    ]
                ),

                // initial setup stuff
                GoRoute(path: "permissions",
                    builder: (context, state) => const PermissionsScreen(),
                ),
                GoRoute(path: "setbooru",
                    builder: (context, state) => const SetBooruScreen(),
                ),
            ]
        ),
    ]
);

void main() async {
    runApp(const App());

    if(isDestkop()) {
        doWhenWindowReady(() {
            const initialSize = Size(420, 260);
            appWindow.minSize = initialSize;
            appWindow.size = const Size(1280, 720);
            appWindow.alignment = Alignment.center;
            appWindow.show();
        });
    }
}

class App extends StatefulWidget {
    const App({super.key});

    State<App> createState() => _AppState();
}

class _AppState extends State<App> {

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return SharedPreferencesBuilder(
            builder: (_, prefs) => ListenableBuilder(
                listenable: themeListener,
                builder: (context, _) => DynamicColorBuilder(
                    builder: (lightDynamic, darkDynamic) {
                        var theme = generateTheme(
                            darkDynamic: darkDynamic,
                            lightDynamic: lightDynamic,
                            monet: prefs.getBool("monet") ?? settingsDefaults["monet"]
                        );

                        final int themeModeIndex = ["system", "light", "dark"].indexWhere((theme) => (prefs.getString("theme") ?? settingsDefaults["theme"]) == theme);

                        return MaterialApp.router(
                            theme: theme["light"],
                            darkTheme: theme["dark"],
                            themeMode: ThemeMode.values[themeModeIndex], 
                            routerConfig: _router,
                        );
                    }
                )
            )
        );
    }

    @override
    void initState() {
        super.initState();
        checkForUpdates().then((ver) async {
            await Future.delayed(const Duration(seconds: 1));
            if(!(await ver.isCurrentLatest()) && _router.routerDelegate.navigatorKey.currentContext != null) {
                showDialog(
                    context: _router.routerDelegate.navigatorKey.currentContext!,
                    builder: (context) => UpdateAvaiableDialog(ver: ver),
                );
            };
        }).catchError((err) {debugPrint(err);});
    }

    final Color _brandColor = Colors.deepPurple;

    Map<String, ThemeData> generateTheme({ColorScheme? lightDynamic, ColorScheme? darkDynamic, bool monet = true}) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (monet && lightDynamic != null && darkDynamic != null) {
            lightColorScheme = lightDynamic.harmonized();
            darkColorScheme = darkDynamic.harmonized();
        } else {
            // Otherwise, use fallback schemes.
            lightColorScheme = ColorScheme.fromSeed(
                seedColor: _brandColor
            );
            darkColorScheme = ColorScheme.fromSeed(
                seedColor: _brandColor,
                brightness: Brightness.dark,
            );
        }

        return {
            "light": ThemeData.from(colorScheme: lightColorScheme),
            "dark": ThemeData.from(colorScheme: darkColorScheme),
        };
    }
}