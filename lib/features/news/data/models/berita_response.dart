class BeritaResponse {
  final int? id;
  final String? date;
  final RenderedText? title;
  final RenderedText? content;
  final RenderedText? excerpt;
  final EmbeddedContent? embedded;

  BeritaResponse({
    this.id,
    this.date,
    this.title,
    this.content,
    this.excerpt,
    this.embedded,
  });

  factory BeritaResponse.fromJson(Map<String, dynamic> json) {
    return BeritaResponse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      date: json['date']?.toString(),
      title: json['title'] != null ? RenderedText.fromJson(json['title']) : null,
      content: json['content'] != null ? RenderedText.fromJson(json['content']) : null,
      excerpt: json['excerpt'] != null ? RenderedText.fromJson(json['excerpt']) : null,
      embedded: json['_embedded'] != null ? EmbeddedContent.fromJson(json['_embedded']) : null,
    );
  }

  /// Helper untuk mendapatkan URL gambar featured
  String? get imageUrl {
    final mediaList = embedded?.featuredMedia;
    if (mediaList != null && mediaList.isNotEmpty) {
      final url = mediaList.first.sourceUrl;
      if (url != null && url.trim().isNotEmpty) {
        return url.trim();
      }
    }
    return null;
  }

  /// Helper untuk mendapatkan nama kategori
  String get categoryName {
    final terms = embedded?.terms;
    if (terms != null && terms.isNotEmpty) {
      final firstGroup = terms.first;
      if (firstGroup.isNotEmpty) {
        final name = firstGroup.first.name;
        if (name != null && name.trim().isNotEmpty && name.toLowerCase() != 'uncategorized') {
          return name.trim();
        }
      }
    }
    return 'Berita';
  }

  /// Helper untuk mendapatkan nama penulis / humas
  String get authorName {
    final authors = embedded?.authors;
    if (authors != null && authors.isNotEmpty) {
      final name = authors.first.name;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    }
    return 'Humas';
  }

  /// Helper untuk judul bersih dari HTML entities
  String get displayTitle {
    final raw = title?.rendered ?? '';
    return _unescapeHtml(raw);
  }

  static String _unescapeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&hellip;', '...')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}

class RenderedText {
  final String rendered;

  RenderedText({required this.rendered});

  factory RenderedText.fromJson(Map<String, dynamic> json) {
    return RenderedText(
      rendered: json['rendered']?.toString() ?? '',
    );
  }
}

class EmbeddedContent {
  final List<AuthorItem>? authors;
  final List<FeaturedMediaItem>? featuredMedia;
  final List<List<TermItem>>? terms;

  EmbeddedContent({
    this.authors,
    this.featuredMedia,
    this.terms,
  });

  factory EmbeddedContent.fromJson(Map<String, dynamic> json) {
    List<AuthorItem>? authors;
    if (json['author'] is List) {
      authors = (json['author'] as List)
          .map((item) => AuthorItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<FeaturedMediaItem>? featuredMedia;
    final rawMedia = json['wp:featuredmedia'];
    if (rawMedia is List) {
      featuredMedia = rawMedia
          .map((item) => FeaturedMediaItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<List<TermItem>>? terms;
    final rawTerms = json['wp:term'];
    if (rawTerms is List) {
      terms = [];
      for (final group in rawTerms) {
        if (group is List) {
          final termList = group
              .whereType<Map<String, dynamic>>()
              .map((item) => TermItem.fromJson(item))
              .toList();
          terms.add(termList);
        }
      }
    }

    return EmbeddedContent(
      authors: authors,
      featuredMedia: featuredMedia,
      terms: terms,
    );
  }
}

class AuthorItem {
  final String? name;

  AuthorItem({this.name});

  factory AuthorItem.fromJson(Map<String, dynamic> json) {
    return AuthorItem(
      name: json['name']?.toString(),
    );
  }
}

class FeaturedMediaItem {
  final String? sourceUrl;

  FeaturedMediaItem({this.sourceUrl});

  factory FeaturedMediaItem.fromJson(Map<String, dynamic> json) {
    return FeaturedMediaItem(
      sourceUrl: json['source_url']?.toString(),
    );
  }
}

class TermItem {
  final String? name;

  TermItem({this.name});

  factory TermItem.fromJson(Map<String, dynamic> json) {
    return TermItem(
      name: json['name']?.toString(),
    );
  }
}
