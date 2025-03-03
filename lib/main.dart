import 'dart:async';
import 'dart:io';

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/components/dialogs/download_dialog.dart';
import 'package:localbooru/routing.dart';
import 'package:localbooru/utils/clipboard_extractor.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:localbooru/utils/update_checker.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/views/permissions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:window_manager/window_manager.dart';

import 'package:fvp/fvp.dart' as fvp;

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

    WidgetsFlutterBinding.ensureInitialized();
    
    if(isDesktop()) {
        await windowManager.ensureInitialized();
        final prefs = await SharedPreferences.getInstance();

        WindowOptions windowOptions = WindowOptions(
            size: const Size(1280, 720),
            minimumSize: const Size(420, 260),
            center: true,
            backgroundColor: Colors.transparent,
            skipTaskbar: false,
            titleBarStyle: prefs.getBool("custom_frame") ?? settingsDefaults["custom_frame"] ? TitleBarStyle.hidden : TitleBarStyle.normal
        );

        windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.show();
        });
    }

    fvp.registerWith();

    runApp(const App());

    // if(isDesktop()) {
    //     doWhenWindowReady(() {
    //         appWindow.size = const Size(1280, 720);
    //         appWindow.minSize = const Size(420, 260);
    //         appWindow.alignment = Alignment.center;
    //         appWindow.show();
    //     });
    // }
}

Future<bool> hasExternalStoragePerms() async{
    final permission = await getStoragePermission();
    if (isMobile()) return await permission.status.isGranted;
    return true;
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
                            debugShowCheckedModeBanner: true,
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
            await Future.delayed(const Duration(milliseconds: 500));
            final routerContext = router.routerDelegate.navigatorKey.currentContext;

            final sharedMedia = value[0];

            if(routerContext != null && routerContext.mounted) {
                switch(sharedMedia.type) {
                    case SharedMediaType.file:
                    case SharedMediaType.image:
                    case SharedMediaType.video:
                        routerContext.push("/manage_image", extra: PresetManageImageSendable(PresetImage(
                            image: File(sharedMedia.path)
                        )));
                        break;
                    case SharedMediaType.text:
                    case SharedMediaType.url:
                        final String text = sharedMedia.path;
                        final uri = Uri.tryParse(text);
                        if(uri == null) return;
                        importImageFromURL(text).then((preset) {
                            routerContext.push("/manage_image", extra: handleSendable(preset));
                        })
                        .onError((error, stack) {
                            if(error.toString() == "Unknown file type" || error.toString() == "Not a URL") {
                                Future.delayed(const Duration(milliseconds: 1)).then((value) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown service or invalid image URL inserted")));
                                });
                            } else {
                                throw error!;
                            }
                        });
                }
            } else {
                Future.delayed(const Duration(milliseconds: 1)).then((value) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not add URL")));
                });
            }
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