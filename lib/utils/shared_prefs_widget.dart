import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesBuilder extends StatelessWidget {
    const SharedPreferencesBuilder({super.key, required this.builder});
    
    final Widget Function(BuildContext context, SharedPreferences prefs) builder;

    @override
    Widget build(BuildContext context) {
        return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
                if(snapshot.hasData) {
                    return builder(context, snapshot.data!);
                } else if(snapshot.hasError) {
                    throw snapshot.error!;
                }
                return const Center(child: CircularProgressIndicator());
            },
        );
    }
}