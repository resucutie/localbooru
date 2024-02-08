import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget{
    const PermissionsScreen({super.key});

    @override
    State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>{
    @override
    Widget build(BuildContext context) {
        return Scaffold (
            appBar: WindowFrameAppBar(
                title: "Setup",
                appBar: AppBar(
                    title: const Text("Permissions"),
                )
            ),
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Text("To use this application, you will have to give permissions to manage external storage", textAlign: TextAlign.center,),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                label: const Text("Give storage permissions"),
                                icon: const Icon(Icons.folder),
                                onPressed: () async {
                                    final status = await Permission.manageExternalStorage.request();
                                    if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
                                        if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                content: Text("don't be so scawed i wont mess with ur pwone :3"),
                                            ));
                                        }
                                        // throw "Please allow storage permission to upload files";
                                    } else {
                                        if (context.mounted) context.go("/");
                                    }
                                },
                            )
                        ],
                    ),
                )
            )
        );
    }
}
