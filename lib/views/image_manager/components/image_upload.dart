import 'dart:async';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/utils/clipboard_extractor.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/video_view.dart';
import 'package:mime/mime.dart';
import 'package:super_clipboard/super_clipboard.dart';

class ImageUploadForm extends StatelessWidget {
    const ImageUploadForm({super.key, required this.onChanged, this.onCompressed, required this.validator, this.currentValue = "", this.orientation = Orientation.portrait});
    
    final ValueChanged<List<File>> onChanged;
    final ValueChanged<String>? onCompressed;
    final FormFieldValidator<String> validator;
    final String currentValue;
    final Orientation orientation;
    
    @override
    Widget build(BuildContext context) {
        return FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validator,
            builder: (FormFieldState state) {
                return Flex(
                    direction: orientation == Orientation.portrait ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                        Container(
                            constraints: BoxConstraints(maxHeight: 400, maxWidth: orientation == Orientation.landscape ? 400 : double.infinity),
                            child: DottedBorder(
                                strokeWidth: 2,
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(24),
                                color: state.hasError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                                    child: TextButton(
                                        style: TextButton.styleFrom(
                                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero,),
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(100, 100),
                                        ),
                                        onPressed: () async {
                                            final files = await selectFileModal(context: context);
                                            if (files != null) {
                                                state.didChange(files.first.path);
                                                onChanged(files);
                                            }
                                        },
                                        child: Builder(builder: (context) {
                                            if(currentValue.isEmpty) {
                                                return const Icon(Icons.add);
                                            } else {
                                                if(lookupMimeType(currentValue)!.startsWith("video/")) return IgnorePointer(
													child: VideoView(currentValue, showControls: false, soundOnStart: false,),
												);
                                                return Image(
                                                    image: ResizeImage(
                                                        FileImage(File(currentValue)),
                                                        height: 400
                                                    )
                                                );
                                            }
                                        },),
                                    ),
                                )
                            ),
                        ),
                        if(!currentValue.isEmpty) Padding(
                            padding: const EdgeInsets.all(8),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Container(
                                    constraints: BoxConstraints(
                                        minHeight: 80,
                                        maxWidth: orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 3 : double.infinity //bad code
                                    ),
                                    child: FileInfo(File(currentValue),
                                        onCompressed: (compressed) {
                                            if(onCompressed != null) onCompressed!(compressed.path);
                                            state.didChange(compressed.path);
                                        }
                                    ),
                                ),
                            ),
                        ),
                        if(state.hasError) Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error),)
                    ],
                );
            },
        );
    }
}

// todo: move somewhere else
Future<List<File>?> selectFileModal({required BuildContext context}) async {
    final output = await showDialog<_PickerType>(context: context, builder: (context) {
        return Dialog(
            child: Container(
                constraints: BoxConstraints(maxWidth: 500),
                padding: EdgeInsets.all(16),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ListTile(
                            title: Text("Select a file"),
                            leading: Icon(Icons.insert_drive_file),
                            onTap: () => Navigator.pop(context, _PickerType.file),
                        ),
                        ListTile(
                            title: Text("Copy from clipboard"),
                            leading: Icon(Icons.copy),
                            onTap: () => Navigator.pop(context, _PickerType.clipboard),
                        ),
                    ],
                ),
            ),
        );
    },);
    if(output == _PickerType.clipboard) {
        final clipboard = SystemClipboard.instance;
        if(clipboard == null) return null;
        final reader = await clipboard.read();
        final types = await obtainValidFileTypeOnClipboard(reader);
        return await Future.wait(types.map((type) => getImageFromClipboard(reader: reader, fileType: type)));
    } else return await openFilePicker();
}

Future<List<File>?> openFilePicker() async {
    FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
    return pickerResult?.files.map((file) => File(file.path!)).toList();
}

enum _PickerType {file, clipboard}