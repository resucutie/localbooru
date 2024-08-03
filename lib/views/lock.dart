import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:localbooru/utils/platform_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LockScreen extends StatefulWidget{
    const LockScreen({super.key, required this.child});

    final Widget child;

    @override
    State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver{
    final LocalAuthentication auth = LocalAuthentication();
    
    bool isImportProgressDialogOpen = false;
    bool hasAuthBeenAsked = false;

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
        lockListener.addListener(updateUI);
        importListener.addListener(updateImportSnackBar);
        isAuthHideoutEnabled().then((hasAuth) {
            if(hasAuth) lockListener.lock();
        },);
    }

    void updateUI() {
        setState(() {});
    }

    bool _isImporting = false;
    void updateImportSnackBar() {
        if(importListener.isImporting) {
            if(!_isImporting && isMobile()) {
                setState(() => _isImporting = true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    dismissDirection: DismissDirection.up,
                    content: const ImportSnackBarContents(),
                    padding: EdgeInsets.zero,
                    duration: const Duration(days: 365),
                    showCloseIcon: true,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                        bottom: MediaQuery.sizeOf(context).height - MediaQuery.viewPaddingOf(context).top - 60,
                        left: 15,
                        right: 15
                    ),
                ));
            }
        } else {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            setState(() => _isImporting = false);
        }
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        lockListener.removeListener(updateUI);
        importListener.removeListener(updateImportSnackBar);
        super.dispose();
    }

    Future<bool> isAuthHideoutEnabled() async {
        final prefs = await SharedPreferences.getInstance();
        return isMobile()
            && (prefs.getBool("auth_lock") ?? settingsDefaults["auth_lock"])
            && await auth.isDeviceSupported();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) async {
        super.didChangeAppLifecycleState(state);
        if(!(await isAuthHideoutEnabled())) return;

        if(state != AppLifecycleState.resumed) {
            await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
            if(state != AppLifecycleState.inactive) {
                lockListener.lock();
            }
        } else {
            await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
            if(lockListener.isLocked && !hasAuthBeenAsked) authToUnlock();
        }
    }

    void authToUnlock() async {
        try {
            final didAuthenticate = await auth.authenticate(
                localizedReason: "Booru is currently locked"
            );
            if(didAuthenticate) {
                lockListener.unlock();
                hasAuthBeenAsked = false;
                if(context.mounted) ScaffoldMessenger.of(context).removeCurrentSnackBar();
            } else {
                hasAuthBeenAsked = true;
            }
        } on PlatformException catch (error) {
            final String message = switch(error.code) {
                auth_error.otherOperatingSystem => "This system shouldn't have any support for authentication lock",
                auth_error.notAvailable || auth_error.notEnrolled || auth_error.passcodeNotSet => "You don't have any auth system avaiable",
                auth_error.lockedOut => "You tried too many times. Please wait till your system allows",
                _ => error.message!
            };
            if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
    }

    @override
    Widget build(BuildContext context) {
        return IndexedStack(
            index: lockListener.isLocked ? 0 : 1,
            children: [
                Scaffold(
                    body: Center(
                        child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                
                                children: [
                                    Icon(Icons.lock, size: 96, color: Theme.of(context).colorScheme.primary,),
                                    const SizedBox(height: 16,),
                                    const Text("LocalBooru won't display the contents due to the user having enabled authentication hideout. Please click on the button below and verify your identity to use this app",
                                        textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 64,),
                                    FilledButton.icon(
                                        label: Text(Random().nextInt(200) == 69 ? "unlok" : "Unlock"),
                                        icon: const Icon(Icons.key),
                                        onPressed: authToUnlock,
                                    )
                                ]
                            ),
                        ),
                    ),
                ),
                widget.child
            ],
        );
    }
}

class ImportSnackBarContents extends StatefulWidget {
  const ImportSnackBarContents({super.key});

  @override
  State<ImportSnackBarContents> createState() => _ImportSnackBarContentsState();
}

class _ImportSnackBarContentsState extends State<ImportSnackBarContents> {
    double _progress = 0;

    @override
    void initState() {
        super.initState();
        importListener.addListener(updateProgress);
    }

    @override
    void dispose() {
        importListener.removeListener(updateProgress);
        super.dispose();
    }

    void updateProgress() {
        setState(() => _progress = importListener.progress);
    }
    
    @override
    Widget build(BuildContext context) {
        return Wrap(
            direction: Axis.horizontal,
            children: [
                ProgressIndicatorTheme(
                    data: const ProgressIndicatorThemeData(linearTrackColor: Colors.transparent),
                    child: LinearProgressIndicator(value: _progress, color: Theme.of(context).colorScheme.inversePrimary),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text("Importing image"),
                ),
            ],
        );
    }
}