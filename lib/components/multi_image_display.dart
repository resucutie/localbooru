import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MultipleImage extends StatelessWidget {
    const MultipleImage({super.key, required this.images});

    final List<ImageProvider?> images;

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
                Positioned.fill(
                    child: MultipleImageImageBox(
                        alignment: FractionalOffset.bottomRight,
                        image: images[2],
                    ),
                ),
                Positioned.fill(
                    child: MultipleImageImageBox(
                        alignment: FractionalOffset.center,
                        image: images[1],
                    ),
                ),
                Positioned.fill(
                    child: MultipleImageImageBox(
                        alignment: FractionalOffset.topLeft,
                        image: images[0],
                    ),
                ),
            ],
        );
    }
}

class MultipleImageImageBox extends StatelessWidget {
    const MultipleImageImageBox({super.key, required this.image, this.alignment = Alignment.center});

    final ImageProvider? image;
    final AlignmentGeometry alignment;


    @override
    Widget build(BuildContext context) {
        final Color blankCardColor = Theme.of(context).brightness == Brightness.light ?
            Theme.of(context).colorScheme.surfaceDim :
            Theme.of(context).colorScheme.surfaceBright;
        return FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.8,
            alignment: alignment,
            child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: image != null ?  blankCardColor.withOpacity(0.5) : blankCardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                        )
                    ]
                ),
                child: image != null ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                        image: image!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                    ),
                ) : null,
            ),
        );
    }
}