import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/utils/constants.dart';

class TagPill extends StatefulWidget {
    const TagPill(this.tag, {super.key, this.color = SpecificTagsColors.generic, this.renderObject, this.onTap});

    final String tag;
    final Color color;
    final void Function()? onTap;
    final RenderObject? renderObject;

    @override
    State<TagPill> createState() => _TagPillState();
}
class _TagPillState extends State<TagPill> {
    bool _isHovering = false;
    late LongPressDownDetails longPress;

    void openContextMenu({required Offset offset, required String tag}) {
        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: [
                PopupMenuItem(
                    enabled: false,
                    height: 16,
                    child: Text(tag, maxLines: 1),
                ),
                ...tagItems(tag, context)
            ]
        );
    }

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: widget.onTap,
            onLongPress: () => openContextMenu(offset: getOffsetRelativeToBox(offset: longPress.globalPosition, renderObject: widget.renderObject ?? context.findRenderObject()!), tag: widget.tag),
            onLongPressDown: (details) => longPress = details,
            onSecondaryTapDown: (tap) => openContextMenu(offset: getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: widget.renderObject ?? context.findRenderObject()!), tag: widget.tag),
            child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (details) => setState(() => _isHovering = true),
                onExit: (details) => setState(() => _isHovering = false),
                child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(widget.tag, style: TextStyle(color: widget.color, decoration: _isHovering ? TextDecoration.underline : null, decorationColor: widget.color)),
                ),
            )
        );
    }
}