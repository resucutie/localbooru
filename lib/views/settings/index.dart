import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/main.dart';

class SettingsShell extends StatelessWidget {
    const SettingsShell({super.key, required this.child,});

    final Widget child;

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: WindowFrameAppBar(
                title: "Settings",
                appBar: AppBar(
                    title: const Text("Settings"),
                    leading: IconButton(
                        onPressed: () {if(context.canPop()) context.pop();}, // Handle your on tap here.
                        icon: const Icon(Icons.arrow_back),
                    ),
                ),
            ),
            body: child,
        );
    }
}

class SettingsHome extends StatelessWidget {
    const SettingsHome({super.key,});

    @override
    Widget build(BuildContext context) {
        return ListView(
            children: [
                ListTile(
                    title: const Text("Change booru"),
                    subtitle: const Text("If you want to create or open another booru"),
                    leading: const Icon(Icons.folder),
                    onTap: () => context.push("/setbooru"),
                ),
                const Divider(),
                ListTile(
                    title: const Text("Overall settings"),
                    subtitle: const Text("Options to configure this program"),
                    leading: const Icon(Icons.settings),
                    onTap: () => context.push("/settings/overall_settings"),
                ),
                const Divider(),
                ListTile(
                    title: const Text("Check for updates"),
                    leading: const Icon(Icons.refresh),
                    onTap: () => openUpdaterOnUpdate(),
                )
            ],
        );
    }
}