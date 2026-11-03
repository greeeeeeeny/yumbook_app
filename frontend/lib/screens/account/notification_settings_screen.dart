import 'package:flutter/material.dart';
import 'package:yumbook_app/state/notification_settings_store.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color _bg = Colors.white;
  static const Color _textDark = Color(0xFF383838);
  static const Color _border = Color(0xFFE5E5E5);

  @override
  void initState() {
    super.initState();
    NotificationSettingsStore.instance.ensureLoaded();
  }

  Future<void> _toggle(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    if (NotificationSettingsStore.instance.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't update notification settings. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationSettingsStore.instance,
      builder: (context, _) {
        final store = NotificationSettingsStore.instance;
        final settings = store.settings;

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 30,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Notifications Settings',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (store.isLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  _NotificationRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Push notification',
                    value: settings.pushEnabled,
                    onChanged: (value) =>
                        _toggle(() => store.setPushEnabled(value)),
                  ),
                  const Divider(height: 1, color: _border),
                  _NotificationRow(
                    icon: Icons.mark_email_unread_outlined,
                    title: 'Email notification',
                    value: settings.emailEnabled,
                    onChanged: (value) =>
                        _toggle(() => store.setEmailEnabled(value)),
                  ),
                  const Divider(height: 1, color: _border),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  static const Color _textDark = Color(0xFF383838);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: _textDark,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}