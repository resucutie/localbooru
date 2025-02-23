import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

final Map<String, StyleCounterType> displays = {
    "baba": const StyleCounterType(path: "assets/counter/baba", ext: "gif", preferredSize: 48), //AssetImage for images/gifs
    "squares": const StyleCounterType(path: "assets/counter/squares", ext: "svg", preferredSize: 48), //ExactAssetPicture for svg
    "image-goobers": const StyleCounterType(path: "assets/counter/image-goobers", ext: "png", preferredSize: 81, filterQuality: FilterQuality.high), //AssetImage for images/gifs
    "signs": const StyleCounterType(path: "assets/counter/signs", ext: "png", preferredSize: 57), //AssetImage for images/gifs
};

class StyleCounterType {
    const StyleCounterType({required this.path, required this.ext, this.preferredSize, this.filterQuality = FilterQuality.none});

    final String path;
    final String ext;
    final double? preferredSize;
    final FilterQuality filterQuality;
}

class StyleCounter extends StatelessWidget {
    const StyleCounter({super.key, required this.number, this.display = "squares", this.height});

    final int number;
    final double? height;
    final String display;

    @override
    Widget build(context) {
        return Wrap(
            direction: Axis.horizontal,
            spacing: 8,
            alignment: WrapAlignment.center,
            children: number.toString().trim().split("").map((e) {
                final info = displays[display]!;
                final file = "${info.path}/$e.${info.ext}";
                final finalHeight = height ?? info.preferredSize;
                if(info.ext == "svg") return SvgPicture.asset(file,
                    height: finalHeight,
                    fit: BoxFit.contain,
                    // color: Theme.of(context).colorScheme.primary,
                    theme: SvgTheme(
                        currentColor: Theme.of(context).colorScheme.primary
                    ),
                );
                return Image.asset(file,
                    height: finalHeight,
                    fit: BoxFit.contain,
                    filterQuality: info.filterQuality,
                );
            }).toList()
        );
    }
}