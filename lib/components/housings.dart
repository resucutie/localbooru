import 'package:flutter/material.dart';
import 'package:localbooru/components/drawer.dart';
import 'package:localbooru/utils/listeners.dart';

class DesktopHousing extends StatefulWidget {
    const DesktopHousing({super.key, required this.child, required this.routeUri, this.roundedCorners = false});

    final Widget child;
    final Uri routeUri;
    final bool roundedCorners;

    @override
    State<DesktopHousing> createState() => _DesktopHousingState();
}

class _DesktopHousingState extends State<DesktopHousing> {
    double _importProgress = 0;

    @override
    void initState() {
        importListener.addListener(handleProgressDisplay);
        super.initState();
    }

    @override
    void dispose() {
        importListener.removeListener(handleProgressDisplay);
        super.dispose();
    }

    void handleProgressDisplay() {
        setState(() => _importProgress = importListener.progress);
    }

    @override
    Widget build(context) {
        return Stack(
            children: [
                Row(
                    children: [
                        ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 270),
                            child: DefaultDrawer(
                                displayTitle: false,
                                activeView: widget.routeUri.pathSegments[0],
                                desktopView: true,
                            )
                        ),
                        // const SizedBox(width: 4),
                        Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 270, maxHeight: MediaQuery.of(context).size.height - 2),
                            clipBehavior: widget.roundedCorners ? Clip.antiAlias : Clip.none,
                            decoration: widget.roundedCorners ? const BoxDecoration(
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
                            ) : null,
                            child: widget.child
                        ),
                    ],
                ),
                if(importListener.isImporting) Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(value: _importProgress == 0 ? null : _importProgress,)
                ),
            ],
        );
    }
}

class MobileHousing extends StatefulWidget {
    const MobileHousing({super.key, required this.child});

    final Widget child;
    @override
    State<MobileHousing> createState() => _MobileHousingState();
}

class _MobileHousingState extends State<MobileHousing> {
    double _importProgress = 0;

    @override
    void initState() {
        importListener.addListener(handleProgressDisplay);
        super.initState();
    }

    @override
    void dispose() {
        importListener.removeListener(handleProgressDisplay);
        super.dispose();
    }

    void handleProgressDisplay() {
        setState(() => _importProgress = importListener.progress);
    }

    @override
    Widget build(context) {
        return Stack(
            children: [
                widget.child,
                if(importListener.isImporting) Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                        child: LinearProgressIndicator(value: _importProgress == 0 ? null : _importProgress,)
                    ),
                )
                // Positioned(
                //     top: 0,
                //     left: 0,
                //     right: 0,
                //     child: LinearProgressIndicator(
                //         value: _importProgress == 0 ? null : _importProgress,
                //         minHeight: MediaQuery.of(context).viewPadding.top,
                //     )
                // )
            ],
        );
    }
}