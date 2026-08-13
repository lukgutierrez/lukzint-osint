/// Datos públicos de un perfil de GitHub obtenidos de la API oficial.
class GithubProfile {
  final String login;
  final String? name;
  final String? bio;
  final String? company;
  final String? location;
  final String? blog;
  final String? twitterUsername;
  final String? htmlUrl;
  final String? avatarUrl;
  final int publicRepos;
  final int followers;
  final int following;
  final DateTime? createdAt;

  const GithubProfile({
    required this.login,
    this.name,
    this.bio,
    this.company,
    this.location,
    this.blog,
    this.twitterUsername,
    this.htmlUrl,
    this.avatarUrl,
    required this.publicRepos,
    required this.followers,
    required this.following,
    this.createdAt,
  });

  factory GithubProfile.fromJson(Map<String, dynamic> json) {
    return GithubProfile(
      login: (json['login'] as String?) ?? '',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      company: json['company'] as String?,
      location: json['location'] as String?,
      blog: json['blog'] as String?,
      twitterUsername: json['twitter_username'] as String?,
      htmlUrl: json['html_url'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      publicRepos: (json['public_repos'] as num?)?.toInt() ?? 0,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
