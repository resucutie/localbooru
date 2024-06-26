import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/drawer.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:localbooru/utils/update_checker.dart';
import 'package:localbooru/views/about.dart';
import 'package:localbooru/views/image_manager/peripherals.dart';
import 'package:localbooru/views/image_manager/preset_api.dart';
import 'package:localbooru/views/image_manager/index.dart';
import 'package:localbooru/views/lock.dart';
import 'package:localbooru/views/navigation/home.dart';
import 'package:localbooru/views/navigation/image_view.dart';
import 'package:localbooru/views/navigation/index.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';
import 'package:localbooru/views/navigation/zoomed_view.dart';
import 'package:localbooru/views/set_booru.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/settings/booru_settings/index.dart';
import 'package:localbooru/views/settings/booru_settings/tag_types.dart';
import 'package:localbooru/views/settings/index.dart';
import 'package:localbooru/views/settings/overall_settings.dart';
import 'package:localbooru/views/test_playground.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/views/permissions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> hasExternalStoragePerms() async{
    final permission = await getStoragePermission();
    if (isMobile()) return await permission.status.isGranted;
    return true;
}

final router = GoRouter(
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
                ShellRoute(
                    builder: (context, state, child) => Scaffold(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        appBar: isDesktop() ? const WindowFrameAppBar() : null,
                        body: LockScreen(child: child),
                    ),
                    routes: [
                        ShellRoute(
                            builder: (context, state, child) => MediaQuery.of(context).orientation == Orientation.landscape ? DesktopHousing(routeUri: state.uri, child: child,) : child,
                            routes: [
                                ShellRoute( //main nav shell
                                    builder: (context, state, child) => AddImageDropRegion(child: child),
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
                                        // ShellRoute(
                                        //     builder: (context, state, child) {
                                        //         final String? id = state.pathParameters["id"];
                                        //         if (id == null) return Text("Invalid ID $id");
                                                        
                                        //         return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                        //             booru: booru,
                                        //             id: id,
                                        //             builder: (context, image) {
                                        //                 return ImageViewShell(image: image, shouldShowImageOnPortrait: state.fullPath == "/view/:id", child: child,);
                                        //             }
                                        //         ));
                                        //     },
                                        //     routes: [
                                        //     ]
                                        // ),
                                        GoRoute(path: "view/:id",
                                            builder: (context, state) {
                                                final String? id = state.pathParameters["id"];
                                                if (id == null) return Text("Invalid ID $id");
                                                        
                                                return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                                    booru: booru,
                                                    id: id,
                                                    builder: (context, image) {
                                                        return ImageViewShell(image: image, shouldShowImageOnPortrait: true, child: ImageViewProprieties(image),);
                                                    }
                                                ));
                                            },
                                            routes: [
                                                GoRoute(path: "note",
                                                    builder: (context, state) {
                                                        final String? id = state.pathParameters["id"];
                                                        if(id == null || int.tryParse(id) == null) return Text("Invalid ID $id");

                                                        return BooruLoader( builder: (_, booru) => BooruImageLoader(
                                                            booru: booru,
                                                            id: id,
                                                            builder: (context, image) {
                                                                return ImageViewShell(image: image, shouldShowImageOnPortrait: true, child: NotesView(id: int.parse(id)),);
                                                            }
                                                        ));
                                                    },
                                                )
                                            ]
                                        ),
                                    ]
                                ),
                                // navigation


                                // image add
                                GoRoute(path: "manage_image",
                                    builder: (context, state) {
                                        return const ImageManagerView(shouldOpenRecents: true,);
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
                                        GoRoute(path: "path/:path", name:"drag_path",
                                            builder: (context, state) {
                                                final String? path = state.pathParameters["path"];
                                                if(path == null) return const Text("Invalid URL");
                                                final file = File(path);
                                                if(!File(path).existsSync()) return const Text("Path does not exist");
                                                return ImageManagerView(preset: PresetImage(image: file));
                                            },
                                        ),
                                        GoRoute(path: "url/:url", name:"download_url",
                                            builder: (context, state) {
                                                final String url = state.pathParameters["url"]!;
                                                return FutureBuilder(
                                                    future: PresetImage.urlToPreset(url),
                                                    builder: (context, snapshot) {
                                                        if(snapshot.hasData) {
                                                            return ImageManagerView(preset: snapshot.data);
                                                        }
                                                        if(snapshot.hasError) {
                                                            if(snapshot.error.toString() == "Unknown file type" || snapshot.error.toString() == "Not a URL") {
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
                                GoRoute(path: "about",
                                    builder: (context, state) => const AboutScreen(),
                                ),
                            ]
                        ),

                        // initial setup stuff
                        GoRoute(path: "permissions",
                            builder: (context, state) => const PermissionsScreen(),
                        ),
                        GoRoute(path: "setbooru",
                            builder: (context, state) => const SetBooruScreen(),
                        ),
                        GoRoute(path: "playground",
                            builder: (context, state) => const TestPlaygroundScreen(),
                        ),
                    ]
                ),
                GoRoute(path: "zoom_image/:id",
                    pageBuilder: (context, state) {
                        final String? id = state.pathParameters["id"];
                        if (id == null) return MaterialPage(child: Text("Invalid ID $id"));
                        return CustomTransitionPage(
                            transitionDuration: const Duration(milliseconds: 200),
                            key: state.pageKey,
                            child: BooruLoader(builder: (_, booru) => BooruImageLoader(
                                booru: booru,
                                id: id,
                                builder: (context, image) => ImageViewZoom(image),
                            )),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                );
                            },
                        );
                    }
                ),
            ]
        ),
    ]
);

void main() async {
    // custom error screen because release just yeets the error messages in favor of a gray screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
            color: const Color.fromARGB(255, 255, 0, 0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    const Text("An error happened:\n"),
                    Text(details.exception.toString()),
                    Text(details.stack.toString())
                ],
            ),
        );
    };

    runApp(const App());

    MediaKit.ensureInitialized();

    if(isDesktop()) {
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
                            routerConfig: router,
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
                router.routerDelegate.navigatorKey.currentContext != null
            ) {
                showDialog(
                    context: router.routerDelegate.navigatorKey.currentContext!,
                    builder: (context) => UpdateAvaiableDialog(ver: ver),
                );
            }
        }).catchError((err) {debugPrint(err);});


        Future<void> onShare(List<SharedMediaFile> value) async {
            final String text = value[0].toMap()["path"];
            final uri = Uri.tryParse(text);
            if(uri == null) return;
            await Future.delayed(const Duration(milliseconds: 500));
            final routerContext = router.routerDelegate.navigatorKey.currentContext;
            if(routerContext != null && routerContext.mounted) routerContext.pushNamed("download_url", pathParameters: {"url": uri.toString()});
        }

        if(isMobile()) {
            //shared media
            // Listen to media sharing coming from outside the app while the app is in the memory.
            _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(onShare, onError: (err) {
                debugPrint("getIntentDataStream error: $err");
            });

            // Get the media sharing coming from outside the app while the app is closed.
            ReceiveSharingIntent.instance.getInitialMedia().then((value) async {
                if(value.isNotEmpty) await onShare(value);
                ReceiveSharingIntent.instance.reset();
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
            lightColorScheme = lightDynamic.harmonized().copyWith();
            darkColorScheme = darkDynamic.harmonized();
        } else {
            // Otherwise, use fallback schemes.
            lightColorScheme = ColorScheme.fromSeed(
                seedColor: _brandColor,
            );
            darkColorScheme = ColorScheme.fromSeed(
                seedColor: _brandColor,
                brightness: Brightness.dark,
            );
        }

        return {
            "light": ThemeData.from(colorScheme: lightColorScheme, useMaterial3: true),
            "dark": ThemeData.from(colorScheme: darkColorScheme, useMaterial3: true),
        };
    }
}