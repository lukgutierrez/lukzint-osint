/// Plataforma de redes sociales o perfil público.
enum SocialPlatform {
  instagram,
  tiktok,
  facebook,
  linkedin,
  x,
  youtube,
  github,
  other,
}

extension SocialPlatformLabel on SocialPlatform {
  String get label => switch (this) {
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.tiktok => 'TikTok',
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.linkedin => 'LinkedIn',
        SocialPlatform.x => 'X (Twitter)',
        SocialPlatform.youtube => 'YouTube',
        SocialPlatform.github => 'GitHub',
        SocialPlatform.other => 'Otra',
      };
}

/// Enlace a un perfil público en una red social.
class SocialLink {
  final String id;
  final SocialPlatform platform;
  final String url;
  final String username;

  const SocialLink({
    required this.id,
    required this.platform,
    required this.url,
    this.username = '',
  });

  SocialLink copyWith({
    SocialPlatform? platform,
    String? url,
    String? username,
  }) {
    return SocialLink(
      id: id,
      platform: platform ?? this.platform,
      url: url ?? this.url,
      username: username ?? this.username,
    );
  }
}
