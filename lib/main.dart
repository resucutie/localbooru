import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/browse.dart';
import 'package:localbooru/setbooru.dart';
import 'package:localbooru/utils/platformTools.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import 'package:localbooru/permissions.dart';
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
                ShellRoute(
                    builder: (context, state, child) => BrowseScreen(uri: state.uri, child: child),
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

    if(isDestkop()) {
        doWhenWindowReady(() {
            const initialSize = Size(260, 260);
            appWindow.minSize = const Size(1280, 720);
            appWindow.size = initialSize;
            appWindow.alignment = Alignment.center;
            appWindow.show();
        });
    }
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

class BrowseScreen extends StatelessWidget {
    const BrowseScreen({super.key, required this.child, required this.uri});

    final Widget child;
    final Uri uri;

    bool _isHome() => uri.path == "/home";
    String _getTitle(Uri uri) {
        // Uri.parse(url).queryParameters["tag"].isEmpty();
        final String? tags = uri.queryParameters["tag"];
        if(uri.path.contains("/search")) {
            if(tags != null && tags.isNotEmpty) return "Browse";
            else return "Recent";
        }
        return "Home";
    }
    String? _getSubtitle(Uri uri) {
        final String? index = uri.queryParameters["index"];
        if(uri.path.contains("/search")) {
            final int page = index == null ? 1 : int.parse(index) + 1;
            return "Page $page";
        }
        return null;
    }


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: WindowFrameAppBar(
                appBar: AppBar(
                    // backgroundColor: Colors.transparent,
                    title: Builder(
                        builder: (builder) {
                            final String title = _getTitle(uri);
                            final String? subtitle = _getSubtitle(uri);
                            return ListTile(
                                title: Text(title, style: const TextStyle(fontSize: 20.0)),
                                subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 14.0)) : null,
                                contentPadding: EdgeInsets.zero,
                            );
                        }
                    ),
                    leading: !_isHome() ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                            if(context.canPop()) context.pop();
                        },
                    ) : null,
                ),
            ) ,
            drawer: Drawer(
                child: ListView(
                    padding: EdgeInsets.zero,
                    children: const <Widget>[
                        Text("hi")
                    ],
                ),
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

class WindowFrameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final AppBar appBar;
  final String title;

  const WindowFrameAppBar({super.key, this.height = 32.0, required this.appBar, this.title = "LocalBooru"});

  @override
  Widget build(BuildContext context) {
    if (!isDestkop()) return appBar;
    return Column(
        children: [
            WindowTitleBarBox(
                child: Row(
                    children: [
                        Expanded(
                            child: MoveWindow(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.00, horizontal: 16.00),
                                    child: Text(title)
                                ),
                            )
                        ),
                        const WindowButtons()
                    ],
                )
            ),
            appBar,
        ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height + (isDestkop() ? height : 0));
}

class WindowButtons extends StatelessWidget {
    const WindowButtons({super.key});



    @override
    Widget build(BuildContext context) {
        final buttonColors = WindowButtonColors(
            iconNormal: Theme.of(context).colorScheme.inverseSurface,
            mouseOver: Theme.of(context).colorScheme.primary,
            mouseDown: Theme.of(context).colorScheme.primaryContainer,
            iconMouseOver: Theme.of(context).colorScheme.onPrimary,
            iconMouseDown: Theme.of(context).colorScheme.onPrimaryContainer
        );
        final closeButtonColors = WindowButtonColors(
            iconNormal: Theme.of(context).colorScheme.inverseSurface,
            mouseOver: Theme.of(context).colorScheme.error,
            mouseDown: Theme.of(context).colorScheme.errorContainer,
            iconMouseOver: Theme.of(context).colorScheme.onError,
            iconMouseDown: Theme.of(context).colorScheme.onErrorContainer
        );
        return Wrap(
            children: [
                MinimizeWindowButton(colors: buttonColors),
                MaximizeWindowButton(colors: buttonColors),
                CloseWindowButton(colors: closeButtonColors)
            ],
        );
    }
}