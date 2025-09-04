// data/models/story_model.dart
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:intl/intl.dart'; // Import for DateFormat if used in _parseDate fallback

// --- IMPORT THE PARSEDATE HELPER ---
// Assuming it's kept separate in lib/core/utils/date_formatter.dart
// import '../../core/utils/date_formatter.dart';

// OR define it directly here:
DateTime? _parseDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty || dateStr == "0001-01-01T00:00:00Z") {
    // Handle null, empty, and common zero-date strings explicitly
    return null;
  }
  try {
    DateTime parsed = DateTime.parse(dateStr);
    // Add a sanity check for dates that might indicate an error or default (e.g., year 1)
    if (parsed.year < 1900) {
      // Adjust this threshold if very old dates are valid
      if (kDebugMode)
        print(
            "Warning: Parsed suspiciously old date: $dateStr. Treating as null.");
      return null;
    }
    // Convert to local time zone for consistency within the app's display logic
    return parsed.toLocal();
  } catch (e) {
    if (kDebugMode)
      print(
          "Error parsing date string with DateTime.parse: '$dateStr'. Error: $e");
    // Optional: Add fallback parsing for other common formats if needed
    // try {
    //    // Example: Fallback for "yyyy-MM-dd HH:mm:ss"
    //    DateTime parsedFallback = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateStr, true).toLocal();
    //     if (parsedFallback.year < 1900) {
    //        if (kDebugMode) print("Warning: Parsed suspiciously old date (fallback): $dateStr. Treating as null.");
    //        return null;
    //     }
    //     return parsedFallback;
    // } catch (e2) {
    //      if (kDebugMode) print("Fallback date parsing also failed for '$dateStr'. Error: $e2");
    //      return null; // Return null if all parsing fails
    // }
    return null; // Return null if parsing fails
  }
}

// --- User Class Definition ---
// Define or import your User class. This is a placeholder based on previous context.
class User {
  final String id;
  final String name;
  final String? bio;
  final String? location;
  final String? profileImageUrl;
  final int followers;
  final int following;
  final int stories;

  User({
    required this.id,
    required this.name,
    this.bio,
    this.location,
    this.profileImageUrl,
    this.followers = 0,
    this.following = 0,
    this.stories = 0,
  });
}

// --- Enums ---
enum StoryStatus {
  draft,
  published,
  archived,
}

enum CollaboratorRole { owner, editor, reviewer }

// --- Helper Functions for Enum Parsing/Serialization ---
String collaboratorRoleToString(CollaboratorRole role) {
  // Converts enum to lowercase string (e.g., 'owner', 'editor')
  return role.toString().split('.').last.toLowerCase();
}

StoryStatus _parseStoryStatus(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) return StoryStatus.draft;
  // Case-insensitive matching
  return StoryStatus.values.firstWhere(
      (e) =>
          e.toString().split('.').last.toLowerCase() ==
          statusStr.toLowerCase().trim(), orElse: () {
    if (kDebugMode)
      print(
          "Warning: Could not parse story status '$statusStr', defaulting to draft.");
    return StoryStatus.draft;
  });
}

CollaboratorRole _parseCollaboratorRole(String? roleStr) {
  if (roleStr == null || roleStr.isEmpty)
    return CollaboratorRole.editor; // Default role if missing or empty
  // Case-insensitive matching
  return CollaboratorRole.values.firstWhere(
      (e) =>
          e.toString().split('.').last.toLowerCase() ==
          roleStr.toLowerCase().trim(), orElse: () {
    if (kDebugMode)
      print(
          "Warning: Could not parse collaborator role '$roleStr', defaulting to editor.");
    return CollaboratorRole.editor;
  });
}

// --- Model Classes ---

class Chapter {
  final String id; // Can be int or string from backend, stored as String
  String title;
  String content;
  bool isComplete;

  Chapter({
    required this.id,
    required this.title,
    this.content = '',
    this.isComplete = false,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      // Handle potential 'id' or 'ID' keys, default if missing
      id: (json['id'] ?? json['ID'] ?? 'unknown_chapter_id').toString(),
      // Handle potential 'title' or 'Title' keys
      title: json['title'] as String? ??
          json['Title'] as String? ??
          'Untitled Chapter',
      // Handle potential 'content' or 'Content' keys
      content: json['content'] as String? ?? json['Content'] as String? ?? '',
      // Handle potential 'isComplete' or 'IsComplete' keys
      isComplete:
          json['isComplete'] as bool? ?? json['IsComplete'] as bool? ?? false,
    );
  }

  // Converts Chapter object to JSON for sending TO backend
  Map<String, dynamic> toJson() {
    return {
      // Use keys expected by the backend API (e.g., 'ID', 'Title')
      'ID': id, // Send ID as String, backend might parse it
      'Title': title,
      'Content': content,
      'IsComplete': isComplete,
    };
  }

  // Creates a copy of the Chapter with optional new values
  Chapter copyWith({
    String? id,
    String? title,
    String? content,
    bool? isComplete,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class Collaborator {
  final String
      userId; // Store User ID as String, parsed from backend's int/string
  final String name;
  final String? avatarUrl;
  final CollaboratorRole role;
  final DateTime joinedDate; // Should always have a valid date

  Collaborator({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.joinedDate,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    // Use _parseDate helper for joinedDate, providing a fallback
    DateTime parsedJoinedDate = _parseDate(json['joinedDate'] as String? ??
            json['JoinedDate'] as String? ??
            json['joined_date'] as String?) ??
        DateTime.now(); // Fallback to current time if parsing fails

    return Collaborator(
      // Handle various potential keys for user ID and convert to String
      userId: (json['userId'] ??
              json['UserID'] ??
              json['user_id'] ??
              'unknown_user_id')
          .toString(),
      // Handle various potential keys for name
      name: json['name'] as String? ??
          json['Name'] as String? ??
          'Unknown Collaborator',
      // Handle various potential keys for avatar URL
      avatarUrl: json['avatarUrl'] as String? ??
          json['AvatarURL'] as String? ??
          json['avatar_url'] as String?,
      // Use helper to parse role string
      role: _parseCollaboratorRole(
          json['role'] as String? ?? json['Role'] as String?),
      joinedDate: parsedJoinedDate,
    );
  }

  // Converts Collaborator object to JSON for sending TO backend
  Map<String, dynamic> toJson() {
    // Attempt to convert the String userId back to int if backend expects 'UserID' as int
    int? userIdAsInt = int.tryParse(userId);
    if (userIdAsInt == null && kDebugMode) {
      print(
          "Collaborator.toJson Warning: userId ('$userId') could not be parsed to int for 'UserID' field.");
    }

    return {
      // Use keys expected by the backend API
      'UserID': userIdAsInt, // Send as int if possible, otherwise null
      'Name': name,
      'AvatarURL': avatarUrl,
      'Role': collaboratorRoleToString(role), // Send role as lowercase string
      'JoinedDate':
          joinedDate.toUtc().toIso8601String(), // Send date as UTC ISO string
    };
  }
}

class PendingReviewRequest {
  final String requestId;
  final String userId; // Store User ID as String
  final String userName;
  final String? userAvatarUrl;
  final String details;
  final DateTime requestedDate; // Should always have a valid date
  final String? chapterId; // Store Chapter ID as String

  PendingReviewRequest({
    required this.requestId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.details,
    required this.requestedDate,
    this.chapterId,
  });

  factory PendingReviewRequest.fromJson(Map<String, dynamic> json) {
    // Use _parseDate helper for requestedDate, providing a fallback
    DateTime parsedRequestedDate = _parseDate(
            json['requestedDate'] as String? ??
                json['RequestedDate'] as String? ??
                json['requested_date'] as String?) ??
        DateTime.now(); // Fallback

    return PendingReviewRequest(
      // Handle various potential keys for IDs and convert to String
      requestId: (json['requestId'] ??
              json['RequestID'] ??
              json['request_id'] ??
              'unknown_req_id')
          .toString(),
      userId: (json['userId'] ??
              json['UserID'] ??
              json['user_id'] ??
              'unknown_user_id')
          .toString(),
      userName: json['userName'] as String? ??
          json['UserName'] as String? ??
          'Unknown User',
      userAvatarUrl: json['userAvatarUrl'] as String? ??
          json['UserAvatarURL'] as String? ??
          json['user_avatar_url'] as String?,
      details: json['details'] as String? ??
          json['Details'] as String? ??
          'No details provided',
      requestedDate: parsedRequestedDate,
      chapterId: (json['chapterId'] ?? json['ChapterID'] ?? json['chapter_id'])
          ?.toString(), // Convert potential int ID to String
    );
  }

  // Converts PendingReviewRequest object to JSON for sending TO backend
  Map<String, dynamic> toJson() {
    // Attempt to convert the String userId back to int if backend expects 'UserID' as int
    int? userIdAsInt = int.tryParse(userId);
    if (userIdAsInt == null && kDebugMode) {
      print(
          "PendingReviewRequest.toJson Warning: userId ('$userId') could not be parsed to int for 'UserID' field.");
    }

    return {
      // Use keys expected by the backend API
      'RequestID': requestId,
      'UserID': userIdAsInt, // Send as int if possible
      'UserName': userName,
      'UserAvatarURL': userAvatarUrl,
      'Details': details,
      'RequestedDate':
          requestedDate.toUtc().toIso8601String(), // Send as UTC ISO string
      'ChapterID': chapterId, // Send as String, backend might parse it
    };
  }
}

// Main Story Model
class Story {
  final int id; // Story's own ID, typically int from backend
  final String title;
  final String? description;
  final String? coverImage;
  final String authorId; // Owner's user ID - Store as String
  final String authorName;
  final int likes;
  final int views;
  final DateTime? publishedDate; // Can be null for drafts/archived
  DateTime lastEdited; // Should always have a valid date
  final List<Chapter> chapters; // List of chapters associated with the story
  final String storyType; // e.g., 'Single Story', 'Chapter-based'
  StoryStatus status; // Draft, Published, Archived
  final List<String> genres;

  // Collaboration features
  List<Collaborator> collaborators;
  List<PendingReviewRequest> pendingReviewRequests;
  bool isShareableLinkActive;
  bool isReviewSystemActive;

  Story({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    required this.authorId, // Expect a String ID
    required this.authorName,
    this.likes = 0,
    this.views = 0,
    this.publishedDate,
    required this.lastEdited,
    List<Chapter>? chapters, // Optional list of chapters
    required this.storyType,
    this.status = StoryStatus.draft,
    List<String>? genres, // Optional list of genres
    List<Collaborator>? collaborators,
    List<PendingReviewRequest>? pendingReviewRequests,
    this.isShareableLinkActive = false,
    this.isReviewSystemActive = true,
  })  : chapters = chapters ?? [], // Initialize with empty list if null
        genres = genres ?? [], // Initialize with empty list if null
        pendingReviewRequests =
            pendingReviewRequests ?? [], // Initialize with empty list
        // Initialize collaborators, ensuring owner is present
        collaborators = collaborators ??
            [
              Collaborator(
                userId: authorId, // Use the provided authorId (String)
                name: authorName,
                role: CollaboratorRole.owner,
                // Use publishedDate if available, otherwise lastEdited as join date for owner
                joinedDate: publishedDate ?? lastEdited,
              )
            ] {
    // Ensure the owner is definitely in the collaborators list if it was provided externally
    if (!this.collaborators.any(
        (c) => c.userId == this.authorId && c.role == CollaboratorRole.owner)) {
      this.collaborators.insert(
          0,
          Collaborator(
            userId: this.authorId,
            name: this.authorName,
            role: CollaboratorRole.owner,
            joinedDate: this.publishedDate ?? this.lastEdited,
          ));
      // Optional: Remove duplicates after adding owner if necessary
      final uniqueCollaborators = <String, Collaborator>{};
      for (var collaborator in this.collaborators) {
        // Owner always takes precedence if duplicated
        if (!uniqueCollaborators.containsKey(collaborator.userId) ||
            collaborator.role == CollaboratorRole.owner) {
          uniqueCollaborators[collaborator.userId] = collaborator;
        }
      }
      this.collaborators = uniqueCollaborators.values.toList();
    }
  }

  // Factory constructor to create a Story instance from JSON data
  factory Story.fromJson(Map<String, dynamic> json) {
    // Helper to parse lists safely, handling potential errors in items
    List<T> _parseList<T>(
        dynamic listJson, T Function(Map<String, dynamic>) fromJson) {
      if (listJson is List) {
        return listJson
            .map((item) {
              // Check if item is a Map before trying to parse
              if (item is Map<String, dynamic>) {
                try {
                  return fromJson(item);
                } catch (e) {
                  if (kDebugMode)
                    print("Error parsing item in list: $item. Error: $e");
                  return null; // Skip items that cause parsing errors
                }
              } else {
                if (kDebugMode)
                  print("Skipping non-map item found in list: $item");
                return null; // Skip non-map items
              }
            })
            .whereType<T>() // Filter out nulls resulting from errors or skips
            .toList();
      }
      return []; // Return empty list if input is not a list or is null
    }

    // --- Parse Core Fields ---
    // Parse Author ID (handle int/string variations from backend)
    String parsedAuthorId;
    final dynamic rawAuthorId = json['UserID'] ??
        json['user_id'] ??
        json['AuthorID'] ??
        json['author_id'];
    if (rawAuthorId != null) {
      parsedAuthorId = rawAuthorId.toString();
    } else {
      if (kDebugMode)
        print(
            "Story.fromJson Warning: UserID/AuthorID not found. Defaulting authorId to '0'. JSON Keys: ${json.keys}");
      parsedAuthorId = "0"; // Assign a default or handle error appropriately
    }

    // Parse Author Name (handle variations)
    String parsedAuthorName = json['AuthorName'] as String? ??
        json['author_name'] as String? ??
        // Check if author is nested (less common but possible)
        (json['author'] as Map<String, dynamic>?)?['name'] as String? ??
        'Unknown Author';

    // --- LOGGING FOR DATES ---
    final rawPublishedDate = json['PublishedDate'] ?? json['published_date'];
    final rawLastEditedDate = json['LastEdited'] ?? json['last_edited'];
    final storyIdForLog = json['ID'] ?? json['id'] ?? 'Unknown ID';

    if (kDebugMode)
      print(
          "Story.fromJson (ID: $storyIdForLog): Raw PublishedDate = '$rawPublishedDate', Raw LastEdited = '$rawLastEditedDate'");
    // --- END LOGGING ---

    // Parse Dates using the robust helper function (_parseDate)
    DateTime? parsedPublishedDate = _parseDate(rawPublishedDate as String?);
    DateTime? parsedLastEdited = _parseDate(rawLastEditedDate as String?);

    // --- LOGGING FOR PARSED DATES ---
    if (kDebugMode) {
      print(
          "Story.fromJson (ID: $storyIdForLog): Parsed PublishedDate = $parsedPublishedDate, Parsed LastEdited = $parsedLastEdited");
      if (rawLastEditedDate != null && parsedLastEdited == null) {
        print(
            "Story.fromJson WARNING (ID: $storyIdForLog): lastEdited parsing FAILED for raw value '$rawLastEditedDate'. Fallback needed.");
      }
    }
    // --- END LOGGING ---

    // --- Parse Lists ---
    List<Chapter> parsedChapters = _parseList(
        json['Chapters'] ?? json['chapters'], (c) => Chapter.fromJson(c));
    List<Collaborator> parsedCollaborators = _parseList(
        json['Collaborators'] ?? json['collaborators'],
        (c) => Collaborator.fromJson(c));
    List<PendingReviewRequest> parsedRequests = _parseList(
        json['PendingReviewRequests'] ?? json['pending_review_requests'],
        (r) => PendingReviewRequest.fromJson(r));
    List<String> parsedGenres = (json['Genres'] as List<dynamic>? ??
            json['genres'] as List<dynamic>? ??
            [])
        .map((g) => g.toString())
        .where((g) => g.isNotEmpty) // Ensure no empty strings
        .toList();

    // --- Construct the Story Object ---
    // Use the main constructor which handles collaborator owner logic internally
    return Story(
      // Parse Story ID (handle 'ID' or 'id')
      id: json['ID'] as int? ??
          json['id'] as int? ??
          0, // Default to 0 if missing
      title: json['Title'] as String? ??
          json['title'] as String? ??
          'Untitled Story',
      description:
          json['Description'] as String? ?? json['description'] as String?,
      coverImage:
          json['CoverImage'] as String? ?? json['cover_image'] as String?,
      authorId: parsedAuthorId,
      authorName: parsedAuthorName,
      likes: json['Likes'] as int? ?? json['likes'] as int? ?? 0,
      views: json['Views'] as int? ?? json['views'] as int? ?? 0,
      publishedDate: parsedPublishedDate, // Assign potentially null date
      // Use parsedLastEdited, but provide DateTime.now() as a final fallback if still null
      lastEdited: parsedLastEdited ?? DateTime.now(),
      chapters: parsedChapters,
      storyType: json['StoryType'] as String? ??
          json['story_type'] as String? ??
          'Single Story',
      status: _parseStoryStatus(
          json['Status'] as String? ?? json['status'] as String?),
      genres: parsedGenres,
      collaborators: parsedCollaborators, // Pass parsed list to constructor
      pendingReviewRequests: parsedRequests,
      isShareableLinkActive: json['IsShareableLinkActive'] as bool? ??
          json['is_shareable_link_active'] as bool? ??
          false,
      isReviewSystemActive: json['IsReviewSystemActive'] as bool? ??
          json['is_review_system_active'] as bool? ??
          true,
    );
  }

  // Converts Story object to JSON for sending TO backend
  Map<String, dynamic> toJson(
      {bool includeChapters = false, bool includeCollaborators = false}) {
    // Attempt to convert the String authorId back to int if backend expects 'UserID' as int
    int? authorIdAsInt = int.tryParse(authorId);
    if (authorIdAsInt == null && kDebugMode) {
      print(
          "Story.toJson Warning: authorId ('$authorId') is not a valid integer string. Sending null for 'UserID'.");
    }

    // Base payload for story metadata update/create
    final Map<String, dynamic> payload = {
      // Use keys expected by the backend API (e.g., 'ID', 'Title', 'UserID')
      'ID': id,
      'Title': title,
      'Description': description,
      'CoverImage': coverImage,
      'UserID': authorIdAsInt, // Send as int if possible
      'Likes': likes,
      'Views': views,
      // Send dates as UTC ISO 8601 strings, handle nulls
      'PublishedDate': publishedDate?.toUtc().toIso8601String(),
      'LastEdited':
          lastEdited.toUtc().toIso8601String(), // Send as UTC ISO string
      'StoryType': storyType,
      'Status': status
          .toString()
          .split('.')
          .last
          .toLowerCase(), // Send status as lowercase string
      'Genres': genres,
      'IsShareableLinkActive': isShareableLinkActive,
      'IsReviewSystemActive': isReviewSystemActive,
      // Conditionally include lists based on flags (often not needed for metadata updates)
      if (includeChapters) 'Chapters': chapters.map((c) => c.toJson()).toList(),
      if (includeCollaborators)
        'Collaborators': collaborators.map((c) => c.toJson()).toList(),
      // Pending requests might be handled by separate endpoints
      // 'PendingReviewRequests': pendingReviewRequests.map((r) => r.toJson()).toList(),
    };

    return payload;
  }

  // Creates a copy of the Story with optional new values
  Story copyWith({
    int? id,
    String? title,
    String? description,
    String? coverImage,
    bool clearCoverImage = false, // Flag to explicitly set coverImage to null
    String? authorId,
    String? authorName,
    int? likes,
    int? views,
    DateTime? publishedDate,
    bool clearPublishedDate =
        false, // Flag to explicitly set publishedDate to null
    DateTime? lastEdited,
    List<Chapter>? chapters,
    bool clearChapters = false, // Flag to explicitly clear chapters
    String? storyType,
    StoryStatus? status,
    List<String>? genres,
    List<Collaborator>? collaborators,
    List<PendingReviewRequest>? pendingReviewRequests,
    bool? isShareableLinkActive,
    bool? isReviewSystemActive,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      // Handle clearing the cover image
      coverImage: clearCoverImage ? null : (coverImage ?? this.coverImage),
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      // Handle clearing the published date
      publishedDate:
          clearPublishedDate ? null : (publishedDate ?? this.publishedDate),
      lastEdited: lastEdited ?? this.lastEdited,
      // Handle clearing chapters or copying existing/new list (deep copy recommended)
      chapters: clearChapters
          ? []
          : (chapters ??
              List<Chapter>.from(this.chapters.map((c) => c.copyWith()))),
      storyType: storyType ?? this.storyType,
      status: status ?? this.status,
      // Copy genres (deep copy is simple for strings)
      genres: genres ?? List<String>.from(this.genres),
      // Copy collaborators (shallow copy okay if Collaborator is mostly immutable)
      collaborators:
          collaborators ?? List<Collaborator>.from(this.collaborators),
      // Copy pending requests (shallow copy okay)
      pendingReviewRequests: pendingReviewRequests ??
          List<PendingReviewRequest>.from(this.pendingReviewRequests),
      isShareableLinkActive:
          isShareableLinkActive ?? this.isShareableLinkActive,
      isReviewSystemActive: isReviewSystemActive ?? this.isReviewSystemActive,
    );
  }

  // --- Static Dummy Data Generation ---
  // (Keeping this for testing purposes, ensure User class is accessible)
  static List<Story> generateDummyStories(int count) {
    // --- Placeholder User Class Definition ---
    // If the User class isn't imported or globally available, define it locally for this static method.
    // This should ideally match the actual User class used elsewhere.
    // class User { final String id; final String name; final String? bio; final String? location; final String? profileImageUrl; final int followers; final int following; final int stories; User({ required this.id, required this.name, this.bio, this.location, this.profileImageUrl, this.followers = 0, this.following = 0, this.stories = 0 }); }
    // --- End Placeholder User Class Definition ---

    final dummyOwner = User(
        id: 'user_owner_0', // Use String ID consistently
        name: 'Aranav Kumar',
        bio: 'A passionate storyteller exploring the echoes of tomorrow.',
        location: 'Cyber City',
        profileImageUrl: null,
        followers: 1250,
        following: 150,
        stories: count ~/ 2);

    return List.generate(
      count,
      (index) {
        bool isChapterBased = index % 3 != 0; // More chapter-based stories
        StoryStatus currentStatus = StoryStatus.values[
            index % StoryStatus.values.length]; // Cycle through statuses
        DateTime now = DateTime.now();
        // Ensure lastEdited is always before 'now'
        DateTime lastEditedTime = now.subtract(
            Duration(days: index + 1, hours: index * 2, minutes: index * 15));
        // Ensure published/created date is before or same as lastEdited
        DateTime publishedOrCreatedTime =
            lastEditedTime.subtract(Duration(days: 2 + index % 5));

        DateTime? publishedDateIfApplicable =
            (currentStatus == StoryStatus.published)
                ? publishedOrCreatedTime
                : null;

        List<Chapter> storyChapters = [];
        if (isChapterBased) {
          int chapterCount = 2 + (index % 5); // 2 to 6 chapters
          storyChapters = List.generate(
              chapterCount,
              (i) => Chapter(
                  id: 'ch_${1000 + index}_${i + 1}', // Unique chapter ID
                  title: 'Chapter ${i + 1}: The ${[
                    'Beginning',
                    'Middle',
                    'Climax',
                    'Twist',
                    'End',
                    'Epilogue'
                  ][i % 6]}',
                  content:
                      'This is the detailed content for chapter ${i + 1} of story ${index + 1}. It explores various themes and plot points...',
                  isComplete: (i < chapterCount - 1) ||
                      (index % 2 ==
                          0) // Mark most chapters complete, last one depends
                  ));
        } else {
          // Single story still represented by one chapter internally
          storyChapters = [
            Chapter(
                id: 'ch_${1000 + index}_main',
                title:
                    "Part ${index + 1}", // Use main story title or simple part
                content:
                    'A standalone tale focusing on a singular narrative arc, exploring deep themes within a concise structure.',
                isComplete:
                    true // Single stories are usually complete content-wise
                )
          ];
        }

        // Create owner collaborator using string ID and valid date
        List<Collaborator> storyCollaborators = [
          Collaborator(
            userId: dummyOwner.id, // String ID
            name: dummyOwner.name,
            role: CollaboratorRole.owner,
            joinedDate:
                publishedOrCreatedTime, // Owner joined at creation/publish time
            avatarUrl: dummyOwner.profileImageUrl,
          ),
          // Add other collaborators conditionally
          if (index % 2 != 0 && isChapterBased) // Editor for odd, chapter-based
            Collaborator(
                userId: 'user_editor_${index}',
                name: 'Sam Editor',
                role: CollaboratorRole.editor,
                joinedDate: publishedOrCreatedTime.add(Duration(days: 2)),
                avatarUrl: null),
          if (index % 3 == 1 &&
              isChapterBased) // Reviewer for some chapter-based
            Collaborator(
                userId: 'user_reviewer_${index}',
                name: 'Pat Reviewer',
                role: CollaboratorRole.reviewer,
                joinedDate: publishedOrCreatedTime.add(Duration(days: 1)),
                avatarUrl: null),
        ];

        return Story(
          id: 1000 + index, // Ensure unique positive integer IDs
          title: "Project Chimera: File ${index + 1}", // Example title
          description: isChapterBased
              ? "In a world rebuilt from digital ashes, a fragmented AI seeks the truth behind its own fractured existence."
              : "A lone data scavenger unearths a relic containing the last digital song of a forgotten civilization.",
          // Use a placeholder or null for cover image
          coverImage: (index % 4 == 0)
              ? "https://via.placeholder.com/300x200.png?text=Story+${index + 1}"
              : null,
          authorId: dummyOwner.id, // Pass the String ID
          authorName: dummyOwner.name,
          likes: 25 + (index * 17 % 150), // More varied realistic counts
          views: 110 + (index * 43 % 500),
          publishedDate: publishedDateIfApplicable,
          lastEdited: lastEditedTime, // Assign the calculated past date
          storyType: isChapterBased ? 'Chapter-based' : 'Single Story',
          status: currentStatus,
          genres: [
            'Cyberpunk',
            if (index % 2 == 0) 'Mystery',
            if (index % 3 == 1) 'Thriller',
            'Sci-Fi'
          ].toSet().toList(), // Ensure unique genres
          chapters: storyChapters,
          collaborators: storyCollaborators,
          pendingReviewRequests: [], // Keep empty for simplicity
          isShareableLinkActive: index % 2 == 0,
          isReviewSystemActive: true,
        );
      },
    );
  }
} // End of Story class
