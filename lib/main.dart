import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/dialog_page.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:localbooru/utils/update_checker.dart';
import 'package:localbooru/views/image_manager/loading_screen.dart';
import 'package:localbooru/views/image_manager/preset_api.dart';
import 'package:localbooru/views/image_manager/index.dart';
import 'package:localbooru/views/navigation/home.dart';
import 'package:localbooru/views/navigation/image_view.dart';
import 'package:localbooru/views/navigation/index.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';
import 'package:localbooru/views/set_booru.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/settings/booru_settings/index.dart';
import 'package:localbooru/views/settings/booru_settings/tag_types.dart';
import 'package:localbooru/views/settings/index.dart';
import 'package:localbooru/views/settings/overall_settings.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/views/permissions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
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
                                final String tags = state.uri.queryParameters["tag"] ?? "";
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
                    ]
                ),

                // image add
                GoRoute(path: "manage_image",
                    builder: (context, state) {
                        return const ImageManagerView();
                    },
                    routes: [
                        GoRoute(path: "internal/:id",
                            builder: (context, state) {
                                final String? id = state.pathParameters["id"];
                                if(id == null || int.tryParse(id) == null) return const Text("Invalid route");
                                return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                    booru: booru,
                                    id: id,
                                    builder: (context, image) {
                                        return FutureBuilder(
                                            future: PresetImage.fromExistingImage(image),
                                            builder: (context, snapshot) {
                                                if(snapshot.hasData) {
                                                    return ImageManagerView(preset: snapshot.data);
                                                }
                                                return const Center(child: CircularProgressIndicator());
                                            },
                                        );
                                    }
                                ));
                            },
                        ),
                        GoRoute(path: "url/:url", name:"download_url",
                            builder: (context, state) {
                                final String? url = state.pathParameters["url"];
                                if(url == null) return const Text("Invalid route");
                                return FutureBuilder(
                                    future: PresetImage.urlToPreset(url),
                                    builder: (context, snapshot) {
                                        if(snapshot.hasData) {
                                            return ImageManagerView(preset: snapshot.data);
                                        }
                                        if(snapshot.hasError) {
                                            if(snapshot.error.toString() == "Unknown file type") {
                                                Future.delayed(const Duration(milliseconds: 1)).then((value) {
                                                    context.pop();
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown service or invalid image URL inserted")));
                                                });
                                            } else {
                                                throw snapshot.error!;
                                            }
                                        }
                                        return const ImageManagerLoadingScreen();
                                    },
                                );
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
                                    builder: (context, state) => SharedPreferencesBuilder(
                                        builder: (context, prefs) => OverallSettings(prefs: prefs)
                                    ),
                                ),
                                GoRoute(path: "booru",
                                    builder: (context, state) => SharedPreferencesBuilder(
                                        builder: (context, prefs) => BooruLoader(
                                            builder: (context, booru) => BooruSettings(prefs: prefs, booru: booru,),
                                        )
                                    ),
                                    routes: [
                                        GoRoute(path: "tag_types",
                                            builder: (context, state) => BooruLoader(
                                                builder: (context, booru) => TagTypesSettings(booru: booru),
                                            ),
                                    )
                                    ]
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

    MediaKit.ensureInitialized();

    if(isDestkop()) {
        doWhenWindowReady(() {
            appWindow.size = const Size(1280, 720);
            appWindow.minSize = const Size(420, 260);
            appWindow.alignment = Alignment.center;
            appWindow.show();
        });
    }
}

class App extends StatefulWidget {
    const App({super.key});

    @override
    State<App> createState() => _AppState();
}

class _AppState extends State<App> {
    late StreamSubscription _intentSub;

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

        //updates
        checkForUpdates().then((ver) async {
            await Future.delayed(const Duration(seconds: 1));
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if( !(await ver.isCurrentLatest()) &&
                (prefs.getBool("update") ?? settingsDefaults["update"]) &&
                _router.routerDelegate.navigatorKey.currentContext != null
            ) {
                showDialog(
                    context: _router.routerDelegate.navigatorKey.currentContext!,
                    builder: (context) => UpdateAvaiableDialog(ver: ver),
                );
            }
        }).catchError((err) {debugPrint(err);});


        Future<void> onShare(List<SharedMediaFile> value) async {
            final String text = value[0].toMap()["path"];
            final uri = Uri.tryParse(text);
            if(uri == null) return;
            await Future.delayed(const Duration(milliseconds: 500));
            final routerContext = _router.routerDelegate.navigatorKey.currentContext;
            if(routerContext != null && routerContext.mounted) routerContext.pushNamed("download_url", pathParameters: {"url": uri.toString()});
        }

        if(isMobile()) {
            //shared media
            // Listen to media sharing coming from outside the app while the app is in the memory.
            _intentSub = ReceiveSharingIntent.getMediaStream().listen(onShare, onError: (err) {
                debugPrint("getIntentDataStream error: $err");
            });

            // Get the media sharing coming from outside the app while the app is closed.
            ReceiveSharingIntent.getInitialMedia().then((value) async {
                if(value.isNotEmpty) await onShare(value);
                ReceiveSharingIntent.reset();
            });
        }
    }

    @override
    void dispose() {
        _intentSub.cancel();
        super.dispose();
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