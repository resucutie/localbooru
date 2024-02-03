import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';

class SetBooruScreen extends StatefulWidget{
    const SetBooruScreen({super.key});

    @override
    State<SetBooruScreen> createState() => _SetBooruScreenState();
}

class _SetBooruScreenState extends State<SetBooruScreen>{
    @override
    Widget build(BuildContext context) {
        return Scaffold (
            appBar: AppBar(
                // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: const Text("Set booru path"),
            ),
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Text("Please select a booru", textAlign: TextAlign.center,),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                label: const Text("Select booru"),
                                icon: const Icon(Icons.folder),
                                onPressed: () async {
                                    String? output = await FilePicker.platform.getDirectoryPath();
                                    if(output == null) return;
                                    setBooru(output);
                                    if (context.mounted) context.go("/home");
                                },
                            )
                        ],
                    ),
                )
            )
        );
    }
}
