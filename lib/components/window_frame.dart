import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:window_manager/window_manager.dart';

class WindowFrameAppBar extends StatelessWidget {
    final AppBar? appBar;
    final Widget? title;
    final Color? backgroundColor;

    const WindowFrameAppBar({super.key, this.appBar, this.title = const Text("LocalBooru"), this.backgroundColor});


    @override
    Widget build(BuildContext context) {
        if (!isDesktop()) return appBar ?? const SizedBox(height: 0);
        return Row(
            children: [
                Expanded(
                    child: DragToMoveArea(
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6.00, horizontal: 16.00),
                            color: Colors.transparent,
                            child: title
                        ),
                    ),
                ),
                const WindowButtons()
            ],
        );
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

    void windowMaximizerToggle() async {
        if(await windowManager.isMaximized()) windowManager.unmaximize();
        else windowManager.maximize();
    }

    @override
    Widget build(BuildContext context) {
        return Wrap(
            children: [
                WindowCaptionButton.minimize(
                    brightness: Theme.of(context).brightness,
                    onPressed: windowManager.minimize,
                ),
                (isMaximized ? WindowCaptionButton.unmaximize : WindowCaptionButton.maximize)(
                    brightness: Theme.of(context).brightness,
                    onPressed: windowMaximizerToggle
                ),
                WindowCaptionButton.close(
                    brightness: Theme.of(context).brightness,
                    onPressed: windowManager.close,
                )
                // WindowButton(
                //     hoverColor: Theme.of(context).colorScheme.error,
                //     onPressed: windowManager.close,
                //     child: CloseIcon(
                //         color: buttonIconColor,
                //     ),
                // )
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