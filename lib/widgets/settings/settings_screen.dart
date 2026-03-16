import 'package:flutter/material.dart';

import 'package:hitch_db/app_config.dart';
import 'package:hitch_db/widgets/settings/settings_content.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SettingsContent(
        apiBaseUrl: AppConfig.apiBaseUrl,
      ),
    );
  }
}
