import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hitch_db/app_config.dart';
import 'package:hitch_db/services/auth_session.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Backend API'),
              subtitle: Text(AppConfig.apiBaseUrl),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Log out'),
              subtitle: const Text('Clear the saved JWT and return to login.'),
              onTap: () {
                context.read<AuthSession>().logout();

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account and all associated data.'),
              iconColor: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error,
              onTap: () => {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Account Deletion'),
                      content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                          ),
                          onPressed: () {
                            context.read<AuthSession>().deleteAccount();
                            if (!mounted) {
                              return;
                            }
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  )
              },
            ),
          ),
        ],
      ),
    );
  }
}
