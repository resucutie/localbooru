import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/components/image-display.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import 'package:localbooru/permissions.dart';

import "api/index.dart";

final _router = GoRouter(
    initialLocation: '/',
    routes: [
        GoRoute(path: '/',
            redirect: (context, GoRouterState state) async {
                final status = await Permission.manageExternalStorage.status;
                debugPrint(status.isGranted.toString());
                if (status.isGranted) {
                    return "/posts";
                }
                return "/permissions";
            },
            routes: [
                GoRoute(path: "posts",
                    builder: (context, state) {
                        return const HomeScreen(title: 'Posts');
                    },
                ),
                GoRoute(path: "permissions",
                    builder: (context, state) => const PermissionsScreen(),
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

class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key, required this.title});

    final String title;

    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    String _dir = "";
    List<BooruImage> _files = [];

    void _load () async {
        Booru boorurepo = Booru(_dir);

        List<BooruImage> images = await boorurepo.searchByTags("upper_body");
        debugPrint("List: $images");
        setState(() {
            _files = images;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        const Text(
                            'Current Path:',
                        ),
                        Text(
                            _dir == "" ? "None" : _dir,
                        ),
                        RepoGrid(images: _files)
                    ],
                ),
            ),
            floatingActionButton: Wrap(
              direction: Axis.vertical,
              spacing: 16,
              children: [
                 FloatingActionButton(
                    heroTag: "open",
                    onPressed: () async {
                        debugPrint("_dir: $_dir");
                        String? output = await FilePicker.platform.getDirectoryPath();
                        if(output == null) return;
                        debugPrint(output);
                        setState(() {
                            _dir = output;
                        });
                        _load();
                    },
                    tooltip: 'Open File',
                    child: const Icon(Icons.folder),
                ),
                // FloatingActionButton(
                //     heroTag: "load",
                //     onPressed: () async {
                //         Booru thebooru = Booru(_dir);
                //         Map booruconfig = await thebooru.getRawInfo();
                //         // debugPrint("$booruconfig");
                //     },
                //     tooltip: 'Write File',
                //     child: const Icon(Icons.note_add),
                // ), 
                // FloatingActionButton(
                //     heroTag: "test",
                //     onPressed: _load,
                //     tooltip: 'Test',
                //     child: const Icon(Icons.science),
                // ),
              ],
            ), // This trailing comma makes auto-formatting nicer for build methods.
        );
    }
}

// int incrementThree (int num, {int add = 3, List<int> addConsecutive = const []}) {
//     int res = num + add;
//     // for (num in addConsecutive) {
//     //     res = res + num;
//     // }
//     addConsecutive.forEach((num) => res = res + num);
//     return res;
// }