import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';

class SilverRepoGrid extends StatelessWidget {
    final List<BooruImage> images;
    final VoidCallback? onPressed;
    const SilverRepoGrid({super.key, required this.images, this.onPressed});
  
    @override
    Widget build(BuildContext context) {
        if(images.isEmpty) {
            return const SizedBox.shrink();
        } else {
            return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                ),
                delegate: SliverChildListDelegate(images.map((image) {
                    return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: GestureDetector(
                            onTap: () => {
                                context.push("/view/${image.id}")
                            },
                            child: Image.file(image.getImage(), fit: BoxFit.cover)
                        ),
                    );
                }).toList()),
            );
        }
    }
}