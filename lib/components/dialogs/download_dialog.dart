import 'package:flutter/material.dart';
import 'package:localbooru/utils/listeners.dart';
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
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                )
            ),

        );
    }
}

Future<PresetImage> openDownloadDialog(String url, {required BuildContext context,}) async {
    final future = PresetImage.urlToPreset(url);

    BuildContext? modalContext;
    if(!lockListener.isLocked) showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
            modalContext = context; //horror
            return const DownloadProgressDialog();
        }
    );

    importListener.updateImportStatus(true);

    return await future.whenComplete(() {
        if(modalContext != null) Navigator.of(modalContext!).pop();
        importListener.updateImportStatus(false);
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