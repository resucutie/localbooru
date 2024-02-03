import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/browse.dart';
import 'package:localbooru/setbooru.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import 'package:localbooru/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> hasExternalStoragePerms() async{
    if (Platform.isAndroid || Platform.isIOS) return await Permission.manageExternalStorage.status.isGranted;
    return true;
}

final _router = GoRouter(
    initialLocation: '/home',
    routes: [
        GoRoute(path: '/',
            redirect: (context, GoRouterState state) async {
                final hasPerms = await hasExternalStoragePerms();
                final prefs = await SharedPreferences.getInstance();
                
                if (!hasPerms) {
                    return "/permissions";
                }

                debugPrint(prefs.getString("booruPath"));
                
                if (prefs.getString("booruPath") == null) return "/setbooru";

                return null;
            },
            routes: [
                ShellRoute(
                    builder: (context, state, child) => HomeScreen(child: child),
                    routes: [
                        GoRoute(path: "home",
                            builder: (context, state) => const SearchTagView(),
                        ),
                        GoRoute(path: "search",
                            builder: (context, state)  {
                                final String? tags = state.uri.queryParameters["tag"];
                                debugPrint("queryParams $tags");
                                debugPrint("fullPath ${state.fullPath}");
                                return BooruLoader(
                                    builder: (context, booru) => GalleryViewer(
                                        booru: booru,
                                        tags: state.uri.queryParameters["tag"] ?? "",
                                        index: int.parse(state.uri.queryParameters["index"] ?? "0"),
                                        routeNavigation: true,
                                    ),
                                );
                            }
                        ),
                        GoRoute(path: "recent",
                            redirect: (_, __) => '/search/',
                        )
                    ]
                ),
                GoRoute(path: "permissions",
                    builder: (context, state) => const PermissionsScreen(),
                ),
                GoRoute(path: "setbooru",
                    builder: (context, state) => const SetBooruScreen(),
                )
            ]
        ),
    ]
);

void main() async {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp.router(
            theme: ThemeData(
                primaryColor: Colors.blue,
                // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
                useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system, 
            routerConfig: _router,
        );
    }
}

class HomeScreen extends StatelessWidget {
    const HomeScreen({super.key, required this.child});

    final Widget child;

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: const Text("LocalBooru"),
            ),
            body: child
        );
    }
}

typedef BooruLoaderWidgetBuilder = Widget Function(BuildContext context, Booru booru);
class BooruLoader extends StatelessWidget {
    const BooruLoader({super.key, required this.builder});

    final BooruLoaderWidgetBuilder builder;
    
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Booru>(
            future: getCurrentBooru(),
            builder: (context, AsyncSnapshot<Booru> snapshot) {
                if(snapshot.hasData) {
                    return builder(context, snapshot.data!);
                } else if(snapshot.hasError) {
                    throw snapshot.error!;
                }
                return const Center(child: CircularProgressIndicator());
            }
        );
    }
    
}