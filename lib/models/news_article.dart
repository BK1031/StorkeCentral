

class NewsArticle {
  String id = "";
  String title = "";
  String byLine = "";
  String excerpt = "";
  String pictureUrl = "";
  String date = "";
  String articleUrl = "";
  DateTime createdAt = DateTime.now().toUtc();

  NewsArticle();

  NewsArticle.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    title = json["title"] ?? "";
    byLine = json["by_line"] ?? "";
    excerpt = json["excerpt"] ?? "";
    pictureUrl = json["picture_url"].toString().replaceAll("-430x330", "") ?? "";
    date = json["date"] ?? "";
    articleUrl = json["article_url"] ?? "";
    createdAt = DateTime.tryParse(json["created_at"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() => {
      "id": id,
      "title": title,
      "by_line": byLine,
      "excerpt": excerpt,
      "picture_url": pictureUrl,
      "date": date,
      "article_url": articleUrl,
      "created_at": createdAt.toIso8601String(),
  };
}

/*
{
}
 */