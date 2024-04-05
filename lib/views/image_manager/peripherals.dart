import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/utils/get_website.dart';
import 'package:string_validator/string_validator.dart';

class ImageManagerLoadingScreen extends StatelessWidget {
    const ImageManagerLoadingScreen({super.key});

    @override
    Widget build(context) {
        return Scaffold(
            appBar: WindowFrameAppBar(title: "Image manager",
                appBar: AppBar(
                    title: const Text("Add image"),
                ),
            ),
            body: const Center(
                child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    direction: Axis.vertical,
                    spacing: 32,
                    children: [
                        Text("Downloading image"),
                        CircularProgressIndicator()
                    ],
                ),
            )
        );
    }
}

class InsertURLDialog extends StatefulWidget {
    const InsertURLDialog({super.key});

    @override
    State<InsertURLDialog> createState() => _InsertURLDialogState();
}
class _InsertURLDialogState extends State<InsertURLDialog> {
    TextEditingController controller = TextEditingController();

    void importFromService() {
        context.pushNamed("download_url", pathParameters: {"url": controller.text});
        Navigator.of(context).pop();
    }

    bool allowedToSend() {
        return controller.text.isNotEmpty && isURL(controller.text);
    }

    @override
    Widget build(context) {
        return AlertDialog(
            title: const Text("Import from service"),
            content: Container(
                constraints: const BoxConstraints(minWidth: 600),
                child: TextField(
                    controller: controller,
                    decoration: InputDecoration(icon: getWebsiteIcon(Uri.parse(controller.text))),
                    onSubmitted: (_) {
                        if(allowedToSend()) importFromService();
                    },
                    onChanged: (_) => setState(() {}),
                ),
            ),
            actions: [
                TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text("Close")
                ),
                TextButton(
                    onPressed: allowedToSend() ? importFromService : null,
                    child: const Text("Import")
                )
            ],
        );
    }
}

class RatingChooserDialog extends StatelessWidget {
    const RatingChooserDialog({super.key, this.selected, this.hasNull = false});

    final Rating? selected;
    final bool hasNull;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Rating"),
            contentPadding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    for (final rating in [if(hasNull) null, Rating.safe, Rating.questionable, Rating.explicit, Rating.illegal]) RadioListTile(
                        groupValue: selected,
                        value: rating,
                        title: Text(rating == null ? "None" : rating.name.replaceFirstMapped(rating.name[0], (match) => rating.name[0].toUpperCase())),
                        onChanged: (value) => Navigator.of(context).pop(value ?? "None"),
                    ),
                ],
            ),
            actions: [
                TextButton(onPressed: Navigator.of(context).pop, child: const Text("Close"))
            ],
        );
    }
}