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

bool isLocked = false;

class LockScreen extends StatefulWidget{
    const LockScreen({super.key, required this.child});

    final Widget child;

    @override
    State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver{
    final LocalAuthentication auth = LocalAuthentication();

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
        forceLockScreenListener.addListener(enableLock);
    }

    void enableLock() {
        setState(() {
            isLocked = true;
        });
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        forceLockScreenListener.removeListener(enableLock);
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) async {
        super.didChangeAppLifecycleState(state);
        final prefs = await SharedPreferences.getInstance();
        if(!(isMobile()
            && (prefs.getBool("auth_lock") ?? settingsDefaults["auth_lock"])
            && await auth.isDeviceSupported()
        )) return;

        if(state != AppLifecycleState.resumed) {
            await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
            if(state != AppLifecycleState.inactive) {
                enableLock();
            }
        } else {
            await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        }

    }

    @override
    Widget build(BuildContext context) {
        return isLocked ? Scaffold (
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
                                label: Text(Random().nextInt(100) == 69 ? "unlok" : "Unlock"),
                                icon: const Icon(Icons.key),
                                onPressed: () async {
                                    try {
                                        final didAuthenticate = await auth.authenticate(
                                            localizedReason: "Booru is currently locked"
                                        );
                                        if(didAuthenticate) setState(() => isLocked = false);
                                    } on PlatformException catch (error) {
                                        final String message = switch(error.code) {
                                            auth_error.otherOperatingSystem => "This system shouldn't have any support for authentication lock",
                                            auth_error.notAvailable || auth_error.notEnrolled || auth_error.passcodeNotSet => "You don't have any auth system avaiable",
                                            auth_error.lockedOut => "You tried too many times. Please wait till your system allows",
                                            _ => error.message!
                                        };
                                        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                                    }
                                },
                            )
                        ]
                    ),
                ),
            ),
        ) : widget.child;
    }
}
