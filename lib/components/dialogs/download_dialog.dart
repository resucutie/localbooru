import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/views/image_manager/preset/index.dart';

class DownloadProgressDialog extends StatefulWidget {
    const DownloadProgressDialog({super.key});

    @override
    State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}
class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(context) {
        return const AlertDialog(
            title: Text("Importing"),
            content: SizedBox(
                width: 500,
                child: LinearProgressIndicator()
            ),

        );
    }
}

Future<PresetImage> openDownloadDialog(String url, {required BuildContext context,}) async {
    final future = PresetImage.urlToPreset(url);

    late BuildContext modalContext;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
            modalContext = context; //horror
            return const DownloadProgressDialog();
        }
    );

    return await future.whenComplete(() {
        Navigator.of(modalContext).pop();
    });
}

// .onError((error, stack) {
//         if(error.toString() == "Unknown file type" || error.toString() == "Not a URL") {
//             Future.delayed(const Duration(milliseconds: 1)).then((value) {
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unknown service or invalid image URL inserted")));
//             });
//         } else {
//             throw error!;
//         }
//     })