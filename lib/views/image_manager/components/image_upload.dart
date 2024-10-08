import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/video_view.dart';
import 'package:mime/mime.dart';

class ImageUploadForm extends StatelessWidget {
    const ImageUploadForm({super.key, required this.onChanged, this.onCompressed, required this.validator, this.currentValue = "", this.orientation = Orientation.portrait});
    
    final ValueChanged<List<PlatformFile>> onChanged;
    final ValueChanged<String>? onCompressed;
    final FormFieldValidator<String> validator;
    final String currentValue;
    final Orientation orientation;
    
    @override
    Widget build(BuildContext context) {
        return FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            initialValue: currentValue,
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
                                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
                                            if (result != null) {
                                                state.didChange(result.files.first.path);
                                                onChanged(result.files);
                                            }
                                        },
                                        child: Builder(builder: (context) {
                                            if(state.value.isEmpty) {
                                                return const Icon(Icons.add);
                                            } else {
                                                if(lookupMimeType(state.value)!.startsWith("video/")) return IgnorePointer(child: VideoView(state.value, showControls: false,),);
                                                return Image(
                                                    image: ResizeImage(
                                                        FileImage(File(state.value)),
                                                        height: 400
                                                    )
                                                );
                                            }
                                        },),
                                    ),
                                )
                            ),
                        ),
                        if(!state.value.isEmpty) Padding(
                            padding: const EdgeInsets.all(8),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Container(
                                    constraints: BoxConstraints(
                                        minHeight: 80,
                                        maxWidth: orientation == Orientation.landscape ? MediaQuery.of(context).size.width / 3 : double.infinity //bad code
                                    ),
                                    child: FileInfo(File(state.value),
                                        onCompressed: (compressed) {
                                            state.didChange(compressed.path);
                                            if(onCompressed != null) onCompressed!(compressed.path);
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