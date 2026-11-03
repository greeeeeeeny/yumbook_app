class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }

  /// 백엔드(`/api/account/notification-settings/`) 응답 → 모델.
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
    );
  }

  /// PATCH 본문(snake_case).
  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
    };
  }
}
