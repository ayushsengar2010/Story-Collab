// lib/data/models/user_model.dart
import 'package:flutter/foundation.dart';

class User {
  final int id;
  final String name;
  final String bio;
  final String? profileImage;
  final String location;
  final String? website;
  final int followers;
  final int following;
  final int stories;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.bio,
    this.profileImage,
    required this.location,
    this.website,
    required this.followers,
    required this.following,
    required this.stories,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['ID'] as num?)?.toInt() ?? 0,
      name: json['Name'] as String? ?? 'Unknown',
      bio: json['Bio'] as String? ?? '',
      profileImage: json['ProfileImage'] as String?,
      location: json['Location'] as String? ?? '',
      website: json['Website'] as String?,
      followers: (json['Followers'] as num?)?.toInt() ?? 0,
      following: (json['Following'] as num?)?.toInt() ?? 0,
      stories: (json['StoriesCount'] as num?)?.toInt() ?? 0,
      isVerified: json['IsVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final payload = {
      'ID': id,
      'Name': name,
      'Bio': bio,
      'ProfileImage': profileImage,
      'Location': location,
      'Website': website,
      'Followers': followers,
      'Following': following,
      'StoriesCount': stories,
      'IsVerified': isVerified,
    };
    if (kDebugMode) {
      print('User.toJson: $payload');
    }
    return payload;
  }
}

// lib/data/models/story_model.dart

class Story {
  final int id;
  final String title;
  final String description;
  final String? coverImage;
  final int userId;
  final int likes;
  final int views;
  final DateTime publishedDate;
  final DateTime lastEdited;
  final String storyType;
  final String status;
  final List<String> genres;

  Story({
    required this.id,
    required this.title,
    required this.description,
    this.coverImage,
    required this.userId,
    this.likes = 0,
    this.views = 0,
    required this.publishedDate,
    required this.lastEdited,
    required this.storyType,
    required this.status,
    this.genres = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled Story',
      description: json['description'] as String? ?? '',
      coverImage: json['cover_image'] as String? ?? json['image'] as String?,
      userId: (json['user_id'] as num?)?.toInt() ??
          (json['author_id'] as num?)?.toInt() ??
          0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      publishedDate: json['published_date'],
      lastEdited: DateTime.parse(json['last_edited'] as String? ??
          json['lastEdited'] as String? ??
          DateTime.now().toIso8601String()),
      storyType: json['story_type'] as String? ?? 'Fiction',
      status: json['status'] as String? ?? 'draft',
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    final payload = {
      'id': id,
      'title': title,
      'description': description,
      'cover_image': coverImage ?? '',
      'user_id': userId.toInt(), // Explicitly ensure integer
      'likes': likes,
      'views': views,
      'published_date': publishedDate?.toIso8601String(),
      'last_edited': lastEdited.toIso8601String(),
      'story_type': storyType,
      'status': status,
      'genres': genres,
    };
    if (kDebugMode) {
      print('Story.toJson: Generated payload: $payload');
    }
    return payload;
  }
}
