// models/author_model.dart
class Author {
  final int id;
  final String name;
  final String bio;
  final String? profileImage;
  final String? location;
  final String? website;
  final int followers;
  final int following;
  final String email;
  final int storiesCount;
  final bool isVerified;
  // Password should NOT be part of the frontend model after fetching.

  Author({
    required this.id,
    required this.name,
    required this.bio,
    this.profileImage,
    this.location,
    this.website,
    required this.followers,
    required this.following,
    required this.email,
    required this.storiesCount,
    required this.isVerified,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['ID'] as int,
      name: json['Name'] as String,
      bio: json['Bio'] as String,
      profileImage: json['ProfileImage'] as String?,
      location: json['Location'] as String?,
      website: json['Website'] as String?,
      followers: json['Followers'] as int? ?? 0,
      following: json['Following'] as int? ?? 0,
      email: json['Email'] as String,
      storiesCount: json['StoriesCount'] as int? ?? 0,
      isVerified: json['IsVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
      'Bio': bio,
      'ProfileImage': profileImage,
      'Location': location,
      'Website': website,
      'Followers': followers,
      'Following': following,
      'Email': email,
      'StoriesCount': storiesCount,
      'IsVerified': isVerified,
    };
  }

  @override
  String toString() {
    return 'Author(id: $id, name: "$name", email: "$email", stories: $storiesCount)';
  }
}
