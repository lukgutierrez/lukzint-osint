import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:osint_social_analyzer/core/errors/analysis_exception.dart';
import 'package:osint_social_analyzer/core/network/http_native_client.dart';
import 'package:osint_social_analyzer/data/datasources/github_api_datasource.dart';

class _FakeNativeHttp extends HttpNativeClient {
  _FakeNativeHttp() : super(timeout: const Duration(seconds: 5));

  @override
  Future<NativeHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (url.endsWith('/missing')) {
      return NativeHttpResponse(
        statusCode: 404,
        body: '',
        headers: const {},
        finalUrl: url,
      );
    }
    final payload = {
      'login': 'torvalds',
      'name': 'Linus Torvalds',
      'bio': 'Kernel developer',
      'company': '@linuxfoundation',
      'location': 'Portland, OR',
      'blog': 'https://torvalds.fi',
      'twitter_username': 'torvalds',
      'html_url': 'https://github.com/torvalds',
      'avatar_url': 'https://avatars.githubusercontent.com/u/1024025',
      'public_repos': 8,
      'followers': 243000,
      'following': 0,
      'created_at': '2011-09-03T15:26:22Z',
    };
    return NativeHttpResponse(
      statusCode: 200,
      body: jsonEncode(payload),
      headers: const {'content-type': 'application/json'},
      finalUrl: url,
    );
  }
}

void main() {
  group('GithubApiDatasource', () {
    test('obtiene el perfil público desde la API oficial', () async {
      final api = GithubApiDatasource(_FakeNativeHttp());
      final profile = await api.fetchProfile('torvalds');

      expect(profile.login, 'torvalds');
      expect(profile.name, 'Linus Torvalds');
      expect(profile.publicRepos, 8);
      expect(profile.createdAt, DateTime.parse('2011-09-03T15:26:22Z'));
    });

    test('lanza AnalysisException ante perfil inexistente', () async {
      final api = GithubApiDatasource(_FakeNativeHttp());
      expect(
        () => api.fetchProfile('missing'),
        throwsA(isA<AnalysisException>()),
      );
    });
  });
}
