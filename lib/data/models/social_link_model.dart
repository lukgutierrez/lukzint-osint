import '../../domain/entities/social_link.dart';

/// Serialización JSON de un [SocialLink].
class SocialLinkModel {
  SocialLinkModel._();

  static SocialLink fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: (json['id'] as String?) ?? '',
      platform: SocialPlatform.values.asNameMap()[json['platform']] ??
          SocialPlatform.other,
      url: (json['url'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
    );
  }

  static Map<String, dynamic> toJson(SocialLink link) {
    return {
      'id': link.id,
      'platform': link.platform.name,
      'url': link.url,
      'username': link.username,
    };
  }
}
