import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/utils/get_website.dart';
import 'package:string_validator/string_validator.dart';

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