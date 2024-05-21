import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:window_manager/window_manager.dart';

class WindowFrameAppBar extends StatelessWidget {
    final AppBar? appBar;
    final String title;
    final Color? backgroundColor;

    const WindowFrameAppBar({super.key, this.appBar, this.title = "LocalBooru", this.backgroundColor});


    @override
    Widget build(BuildContext context) {
        if (!isDesktop()) return appBar ?? const SizedBox(height: 0);
        return Row(
            children: [
                Expanded(
                    child: GestureDetector(
                        onTapDown: (details) => windowManager.startDragging(),
                        onDoubleTap: () async {
                            if(await windowManager.isMaximized()) windowManager.unmaximize();
                            else windowManager.maximize();
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6.00, horizontal: 16.00),
                            color: Colors.transparent,
                            child: Text(title)
                        ),
                    ),
                ),
                const WindowButtons()
            ],
        );
                // if(appBar != null) appBar!,
    }
}

class WindowButtons extends StatefulWidget {
    const WindowButtons({super.key});

    @override
    State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
    bool isMaximized = false;

    @override
    void initState() {
        super.initState();
        windowManager.addListener(this);
    }

    @override
    void dispose() {
        windowManager.removeListener(this);
        super.dispose();
    }

    @override
    void onWindowMaximize() {
        setState(() {
            isMaximized = true;
        });
        super.onWindowMaximize();
    }

    @override
    void onWindowUnmaximize() {
        setState(() {
            isMaximized = false;
        });
        super.onWindowMaximize();
    }

    @override
    Widget build(BuildContext context) {
        final buttonIconColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

        return Wrap(
            children: [
                WindowButton(
                    hoverColor: Theme.of(context).colorScheme.primary,
                    onPressed: windowManager.minimize,
                    child: MinimizeIcon(
                        color: buttonIconColor,
                    ),
                ),
                WindowButton(
                    hoverColor: Theme.of(context).colorScheme.primary,
                    onPressed: () async {
                        if(await windowManager.isMaximized()) windowManager.unmaximize();
                        else windowManager.maximize();
                    },
                    child: isMaximized ? RestoreIcon(
                        color: buttonIconColor,
                    ) : MaximizeIcon(
                        color: buttonIconColor,
                    ),
                ),
                WindowButton(
                    hoverColor: Theme.of(context).colorScheme.error,
                    onPressed: windowManager.close,
                    child: CloseIcon(
                        color: buttonIconColor,
                    ),
                )
            ]
        );
    }
}

class WindowButton extends StatefulWidget {
    const WindowButton({super.key, required this.child, required this.hoverColor, this.onPressed});
    final Widget child;
    final Color? hoverColor;
    final Function()? onPressed;

    @override
    State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
    bool isHovering = false;

    @override
    Widget build(BuildContext context) {
        return MouseRegion(
            onEnter: (PointerEnterEvent event) => setState(() => isHovering = true),
            onExit: (PointerExitEvent event) => setState(() => isHovering = false),
            child: GestureDetector(
                onTap: () {if(widget.onPressed != null) widget.onPressed!();},
                child: Container(
                    width: 46,
                    height: 32,
                    color: isHovering && widget.hoverColor != null ? widget.hoverColor : null,
                    child: widget.child
                ),
            ),
        );
    }
}


// taken from https://github.com/bitsdojo/bitsdojo_window/blob/master/bitsdojo_window/lib/src/icons/icons.dart

/// Close
class CloseIcon extends StatelessWidget {
    const CloseIcon({super.key, required this.color});
    final Color color;
    
    @override
    Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Stack(children: [
        // Use rotated containers instead of a painter because it renders slightly crisper than a painter for some reason.
        Transform.rotate(
            angle: pi * .25,
            child: Center(child: Container(width: 14, height: 1, color: color))),
        Transform.rotate(
            angle: pi * -.25,
            child: Center(child: Container(width: 14, height: 1, color: color))),
        ]),
    );
}

/// Maximize
class MaximizeIcon extends StatelessWidget {
  const MaximizeIcon({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => _AlignedPaint(_MaximizePainter(color));
}

class _MaximizePainter extends _IconPainter {
  _MaximizePainter(super.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width - 1, size.height - 1), p);
  }
}

/// Restore
class RestoreIcon extends StatelessWidget {
    const RestoreIcon({
        super.key,
        required this.color,
    });
    final Color color;

    @override
    Widget build(BuildContext context) => _AlignedPaint(_RestorePainter(color));
}

class _RestorePainter extends _IconPainter {
    _RestorePainter(super.color);

    @override
    void paint(Canvas canvas, Size size) {
        Paint p = getPaint(color);
        canvas.drawRect(Rect.fromLTRB(0, 2, size.width - 2, size.height), p);
        canvas.drawLine(const Offset(2, 2), const Offset(2, 0), p);
        canvas.drawLine(const Offset(2, 0), Offset(size.width, 0), p);
        canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height - 2), p);
        canvas.drawLine(Offset(size.width, size.height - 2), Offset(size.width - 2, size.height - 2), p);
    }
}

/// Minimize
class MinimizeIcon extends StatelessWidget {
    const MinimizeIcon({super.key, required this.color});
    final Color color;

    @override
    Widget build(BuildContext context) => _AlignedPaint(_MinimizePainter(color));
}

class _MinimizePainter extends _IconPainter {
    _MinimizePainter(super.color);

    @override
    void paint(Canvas canvas, Size size) {
        Paint p = getPaint(color);
        canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    }
}

/// Helpers
abstract class _IconPainter extends CustomPainter {
    _IconPainter(this.color);
    final Color color;

    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlignedPaint extends StatelessWidget {
    const _AlignedPaint(this.painter);
    final CustomPainter painter;

    @override
    Widget build(BuildContext context) {
        return Align(
            alignment: Alignment.center,
            child: CustomPaint(size: const Size(10, 10), painter: painter)
        );
    }
}

Paint getPaint(Color color, [bool isAntiAlias = false]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..isAntiAlias = isAntiAlias
  ..strokeWidth = 1;