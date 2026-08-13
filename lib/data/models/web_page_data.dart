/// Datos extraídos de una página web pública.
class WebPageData {
  final String url;
  final String title;
  final String description;
  final String? siteName;
  final String? ogType;
  final String? canonical;
  final List<String> headings;

  const WebPageData({
    required this.url,
    required this.title,
    required this.description,
    this.siteName,
    this.ogType,
    this.canonical,
    this.headings = const [],
  });
}
