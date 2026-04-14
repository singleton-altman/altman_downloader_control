/// qBittorrent RSS Item 数据模型
class QBRssItemModel {
  final String? articleId; // 兼容字段，实际 API 使用 id
  final String? id; // API 返回的 id
  final String? author;
  final String? category;
  final String? comments;
  final String? date;
  final String? description;
  final String? link;
  final String? torrentURL;
  final String? title;
  final bool? isRead;

  QBRssItemModel({
    this.articleId,
    this.id,
    this.author,
    this.category,
    this.comments,
    this.date,
    this.description,
    this.link,
    this.torrentURL,
    this.title,
    this.isRead,
  });

  factory QBRssItemModel.fromJson(Map<String, dynamic> json) {
    // 优先使用 id，如果没有则使用 articleId（向后兼容）
    final itemId = json['id'] as String? ?? json['articleId'] as String?;
    
    return QBRssItemModel(
      id: itemId,
      articleId: itemId, // 保持兼容
      author: json['author'] as String?,
      category: json['category'] as String?,
      comments: json['comments'] as String?,
      date: json['date'] as String?,
      description: json['description'] as String?,
      link: json['link'] as String?,
      torrentURL: json['torrentURL'] as String?,
      title: json['title'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? articleId,
      'articleId': articleId ?? id,
      'author': author,
      'category': category,
      'comments': comments,
      'date': date,
      'description': description,
      'link': link,
      'torrentURL': torrentURL,
      'title': title,
      'isRead': isRead,
    };
  }
}

/// qBittorrent RSS Feed 数据模型
class QBRssFeedModel {
  final String? uid;
  final String? url;
  final String? title;
  final int? articleCount;
  final List<QBRssItemModel>? items; // 兼容字段
  final List<QBRssItemModel>? articles; // API 实际返回的字段
  final bool? hasError;
  final bool? isLoading;
  final String? lastBuildDate;

  QBRssFeedModel({
    this.uid,
    this.url,
    this.title,
    this.articleCount,
    this.items,
    this.articles,
    this.hasError,
    this.isLoading,
    this.lastBuildDate,
  });

  factory QBRssFeedModel.fromJson(Map<String, dynamic> json) {
    List<QBRssItemModel>? articlesList;
    
    // 优先使用 articles（API 实际返回），如果没有则使用 items（向后兼容）
    if (json['articles'] != null) {
      if (json['articles'] is List) {
        articlesList = (json['articles'] as List)
            .map((item) => QBRssItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['articles'] is Map) {
        // 如果 articles 是 Map，转换为 List
        final articlesMap = json['articles'] as Map<String, dynamic>;
        articlesList = articlesMap.values
            .map((item) => QBRssItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } else if (json['items'] != null) {
      // 向后兼容旧的 items 字段
      if (json['items'] is List) {
        articlesList = (json['items'] as List)
            .map((item) => QBRssItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (json['items'] is Map) {
        final itemsMap = json['items'] as Map<String, dynamic>;
        articlesList = itemsMap.values
            .map((item) => QBRssItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return QBRssFeedModel(
      uid: json['uid'] as String?,
      url: json['url'] as String?,
      title: json['title'] as String?,
      articleCount: (json['articleCount'] as num?)?.toInt() ?? articlesList?.length,
      items: articlesList, // 保持兼容
      articles: articlesList,
      hasError: json['hasError'] as bool?,
      isLoading: json['isLoading'] as bool?,
      lastBuildDate: json['lastBuildDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'url': url,
      'title': title,
      'articleCount': articleCount,
      'articles': articles?.map((item) => item.toJson()).toList(),
      'items': items?.map((item) => item.toJson()).toList(),
      'hasError': hasError,
      'isLoading': isLoading,
      'lastBuildDate': lastBuildDate,
    };
  }

  /// 获取 items 列表（优先使用 articles，如果没有则使用 items）
  List<QBRssItemModel>? getItems() {
    return articles ?? items;
  }
}

/// qBittorrent RSS Items 响应模型
class QBRssItemsResponse {
  final Map<String, QBRssFeedModel> feeds;

  QBRssItemsResponse({
    required this.feeds,
  });

  factory QBRssItemsResponse.fromJson(Map<String, dynamic> json) {
    final feeds = <String, QBRssFeedModel>{};
    
    json.forEach((key, value) {
      if (value is Map) {
        feeds[key] = QBRssFeedModel.fromJson(value as Map<String, dynamic>);
      }
    });

    return QBRssItemsResponse(feeds: feeds);
  }

  /// 获取所有 RSS items（扁平化）
  List<QBRssItemModel> getAllItems() {
    final allItems = <QBRssItemModel>[];
    for (var feed in feeds.values) {
      final items = feed.getItems();
      if (items != null) {
        allItems.addAll(items);
      }
    }
    return allItems;
  }

  /// 按 Feed 分组获取 items
  Map<String, List<QBRssItemModel>> getItemsByFeed() {
    final itemsByFeed = <String, List<QBRssItemModel>>{};
    feeds.forEach((feedId, feed) {
      final items = feed.getItems();
      if (items != null && items.isNotEmpty) {
        itemsByFeed[feedId] = items;
      }
    });
    return itemsByFeed;
  }
}

