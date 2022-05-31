import 'package:storke_central/models/dining_hall_meal.dart';

class NewsArticle {
  String headline = "";
  String byline = "";
  DateTime date = DateTime.now();
  String excerpt = "";
  String coverUrl = "";
  String articleUrl = "";

  NewsArticle();

  NewsArticle.fromJson(Map<String, dynamic> json) {
    headline = json["headline"] ?? "";
    byline = json["byline"] ?? "";
    date = json["date"] ?? DateTime.now();
    excerpt = json["excerpt"] ?? "";
    coverUrl = json["coverUrl"] ?? "";
    articleUrl = json["articleUrl"] ?? "";
  }

  Map<String, dynamic> toJson() => {
    'headline': headline,
    'byline': byline,
    'date': date,
    'excerpt': excerpt,
    'coverUrl': coverUrl,
    'articleUrl': articleUrl,
  };
}

/*
{
}
 */