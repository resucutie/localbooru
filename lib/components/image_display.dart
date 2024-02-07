import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/utils/defaults.dart';


class SilverRepoGrid extends StatelessWidget {
    const SilverRepoGrid({super.key, required this.images, this.onPressed, this.autoadjustColumns});
    final List<BooruImage> images;
    final Function(BooruImage image)? onPressed;
    final int? autoadjustColumns;
  
    @override
    Widget build(BuildContext context) {
        // it is formatted in this way for better visibility of the formula
        int columns = (
            MediaQuery.of(context).size.width
            /
            (
                (20*50)
                /
                (autoadjustColumns ?? settingsDefaults["grid_size"])
            )
        ).ceil();

        if(images.isEmpty) {
            return const SizedBox.shrink();
        } else {
            return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                ),
                delegate: SliverChildListDelegate(images.map((image) {
                    return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: GestureDetector(
                            onTap: () {if(onPressed != null) onPressed!(image);},
                            child: Image.file(image.getImage(), fit: BoxFit.cover)
                        ),
                    );
                }).toList()),
            );
        }
    }
}