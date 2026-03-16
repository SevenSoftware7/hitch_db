import 'package:flutter/material.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({required this.apiBaseUrl, super.key});

  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Backend API'),
            subtitle: Text(apiBaseUrl),
          ),
        ),
      ],
    );
  }
}
