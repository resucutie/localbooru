import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:path/path.dart' as p;

const setupScreenText = """
This is where you select or create a new booru folder.

If you already have one, select the first option to open the file manager and select it.

If you don't, click the "Create a new one" option, create a new folder on a desired location and select it. It will create the necessary files to host the content of your image repository, a.k.a. a Booru
""";

class SetBooruScreen extends StatelessWidget{
    const SetBooruScreen({super.key});

    @override
    Widget build(BuildContext context) {
        Orientation orientation = MediaQuery.of(context).orientation;

        return Scaffold (
            appBar: WindowFrameAppBar(
                title: "Setup",
                appBar: AppBar(
                    title: const Text("Set Booru Path"),
                )
            ),
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Flex(
                        direction: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: orientation == Orientation.portrait ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                            Flexible(
                                flex: 1,
                                child: Text(setupScreenText, textAlign: orientation == Orientation.landscape ? TextAlign.center: null,)
                            ),
                            SizedBox(
                                height: orientation == Orientation.portrait ? 32 : null,
                                width: orientation == Orientation.landscape ? 64 : null
                            ),
                            Flexible(
                                flex: 1,
                                child: Wrap(
                                    direction: Axis.vertical,
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: orientation == Orientation.landscape ? WrapCrossAlignment.center : WrapCrossAlignment.start,
                                    spacing: 16.0,
                                    children: [
                                        OutlinedButton.icon(
                                            label: const Text("Select an already existing booru"),
                                            icon: const Icon(Icons.folder),
                                            onPressed: () async {
                                                String? output = await FilePicker.platform.getDirectoryPath();
                                                if(output == null) return;
                                                final File repoinfo = File(p.join(output, "repoinfo.json"));
                                                if(!(await repoinfo.exists() && await Directory(p.join(output, "files")).exists())) {
                                                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This booru either does not contain repoinfo.json or the files folder. Please pick a valid booru")));
                                                    return;
                                                }
                                                try{
                                                    final Map<String, dynamic> raw = jsonDecode(await repoinfo.readAsString());
                                                    if(!isValidBooruModel(raw)) throw "it doesn't contain valid props";
                                                } catch(e) {
                                                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("repoinfo.json is corrupted, please fix it")));
                                                    return;
                                                }
                                                await setBooru(output);
                                                if (context.mounted) context.go("/home");
                                            },
                                        ),
                                        FilledButton.icon(
                                            label: const Text("Create a new one"),
                                            icon: const Icon(Icons.add),
                                            onPressed: () async {
                                                String? output = await FilePicker.platform.getDirectoryPath();
                                                if(output == null) return;
                                                await createDefaultBooruModel(output);
                                                setBooru(output);
                                                if (context.mounted) context.go("/home");
                                            },
                                        )
                                    ],
                                ),
                            )
                        ],
                    ),
                )
            )
        );
    }
}
