import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/components/window_frame.dart';

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
                    title: const Text("Overall settings"),
                    subtitle: const Text("Options to configure this program"),
                    leading: const Icon(Icons.settings),
                    onTap: () => context.push("/settings/overall_settings"),
                )
            ],
        );
    }
}