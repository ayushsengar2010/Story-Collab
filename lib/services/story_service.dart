// services/story_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/data/models/author_model.dart'; // Import Author model
import 'package:collabwrite/services/auth_service.dart';
import 'dart:math';

class StoryService {
  static const String _baseUrl = 'http://18.232.150.66:8080';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders(
      {bool requireAuth = true, bool isDeleteOrPostNoBody = false}) async {
    final headers = <String, String>{};
    // Always set Content-Type for POST/PUT/DELETE with body
    if (!isDeleteOrPostNoBody) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (requireAuth) {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        if (kDebugMode) {
          print(
              'StoryService Warning: Auth token not found for a route that requires it.');
        }
        // Optionally throw an error or handle appropriately
        // throw Exception('Authentication required but token is missing.');
      }
    }
    return headers;
  }

  Map<String, dynamic> _buildStoryRequestBody(Story story,
      {bool isCreate = false}) {
    Map<String, dynamic> body = story.toJson(
        // By default, don't include chapters/collaborators in metadata updates
        includeChapters: false,
        includeCollaborators: false);

    // Ensure user_id is handled correctly (prefer user_id, fallback to AuthorID/UserID)
    // The toJson method in Story model should handle converting authorId (String) to UserID (int?)
    // Let's keep the logic primarily in toJson, but double-check here
    if (!body.containsKey('UserID') || body['UserID'] == null) {
      int? authorIdAsInt = int.tryParse(story.authorId);
      body['UserID'] = authorIdAsInt; // Set it if missing or null
      if (kDebugMode && authorIdAsInt == null) {
        print(
            "StoryService Warning: Could not parse story.authorId ('${story.authorId}') to int for UserID field in request body.");
      }
    }
    // Rename UserID to user_id if needed by specific endpoints (check API docs)
    // Example: if /createstories needs 'user_id' instead of 'UserID'
    // if (isCreate && body.containsKey('UserID')) {
    //    body['user_id'] = body.remove('UserID');
    // }

    if (!isCreate) {
      // Ensure LastEdited is always updated for non-create operations
      body['LastEdited'] = DateTime.now().toUtc().toIso8601String();
    }
    if (kDebugMode) {
      print(
          "Prepared Story Request Body for ${isCreate ? 'CREATE' : 'UPDATE'}: ${jsonEncode(body)}");
    }
    return body;
  }

  Future<Story?> createStory(Story storyMetadata) async {
    const String url = '$_baseUrl/createstories';
    final Map<String, dynamic> requestBody =
        _buildStoryRequestBody(storyMetadata, isCreate: true);

    // Re-validate UserID presence after _buildStoryRequestBody
    if (requestBody['UserID'] == null) {
      if (kDebugMode) {
        print(
            'StoryService Error: Valid UserID is required for createStory. Value in payload: ${requestBody['UserID']}. Original authorId: ${storyMetadata.authorId}');
      }
      return null;
    }
    // Ensure Story ID (ID) is present and valid for create
    if (!requestBody.containsKey('ID') ||
        requestBody['ID'] == null ||
        requestBody['ID'] == 0) {
      if (kDebugMode) {
        print(
            'StoryService Error: Valid Story ID is required in the payload for createStory. Current ID in payload: ${requestBody['ID']}');
      }
      return null;
    }

    if (kDebugMode) {
      print(
          "StoryService: POST $url (Story Metadata), Payload: ${jsonEncode(requestBody)}");
    }
    try {
      final response = await http.post(Uri.parse(url),
          headers: await _getHeaders(), body: jsonEncode(requestBody));
      if (kDebugMode) {
        print(
            "StoryService: createStory (Metadata) response ${response.statusCode}, Body: ${response.body}");
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Response might not have chapters, Story.fromJson handles this
        return Story.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error creating story metadata: $e');
      return null;
    }
  }

  // --- Chapter Specific Methods ---

  Future<Chapter?> createChapter(
      {required int storyId,
      required String title,
      required String content,
      int chapterNumber = 1,
      bool isComplete = false}) async {
    const String url = '$_baseUrl/createchapter';
    final Map<String, dynamic> requestBody = {
      "story_id": storyId,
      "title": title,
      "content": content,
      "chapter_number": chapterNumber,
      "is_complete": isComplete,
    };
    if (kDebugMode) {
      print(
          "StoryService: POST $url (Create Chapter), Payload: ${jsonEncode(requestBody)}");
    }
    try {
      final response = await http.post(Uri.parse(url),
          headers: await _getHeaders(), body: jsonEncode(requestBody));
      if (kDebugMode) {
        print(
            "StoryService: createChapter response ${response.statusCode}, Body: ${response.body}");
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Chapter.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error creating chapter for story $storyId: $e');
      return null;
    }
  }

  Future<Chapter?> getChapterById(String chapterId) async {
    final String url = '$_baseUrl/getchapterbyid/$chapterId';
    if (kDebugMode) print("StoryService: GET $url");
    try {
      final response =
          await http.get(Uri.parse(url), headers: await _getHeaders());
      if (kDebugMode) {
        print(
            "StoryService: getChapterById response ${response.statusCode}, Body: ${response.body}");
      }
      if (response.statusCode == 200) {
        return Chapter.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching chapter $chapterId: $e');
      return null;
    }
  }

  Future<List<Chapter>> getChaptersByStory(int storyId) async {
    final String url = '$_baseUrl/getchapterbystory/$storyId';
    if (kDebugMode) {
      print("StoryService: GET $url (Chapters for story $storyId)");
    }
    try {
      final response =
          await http.get(Uri.parse(url), headers: await _getHeaders());
      if (kDebugMode) {
        print(
            "StoryService: getChaptersByStory response ${response.statusCode}, Body: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}");
      }
      if (response.statusCode == 200) {
        // Handle null or empty body for chapters as well
        if (response.body == null ||
            response.body.isEmpty ||
            response.body.toLowerCase() == 'null') {
          if (kDebugMode)
            print(
                "StoryService: getChaptersByStory received null or empty body for story $storyId.");
          return [];
        }
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((data) => Chapter.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print(
              'Failed to load chapters for story $storyId. Status: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching chapters for story $storyId: $e');
      return [];
    }
  }

  Future<Chapter?> updateChapter(
      {required String chapterId,
      required int storyId,
      required String title,
      required String content,
      required int chapterNumber,
      required bool isComplete}) async {
    final String url = '$_baseUrl/updatechapter/$chapterId';
    final Map<String, dynamic> requestBody = {
      "story_id": storyId,
      "title": title,
      "content": content,
      "chapter_number": chapterNumber,
      "is_complete": isComplete,
    };
    if (kDebugMode) {
      print(
          "StoryService: PUT $url (Update Chapter), Payload: ${jsonEncode(requestBody)}");
    }
    try {
      final response = await http.put(Uri.parse(url),
          headers: await _getHeaders(), body: jsonEncode(requestBody));
      if (kDebugMode) {
        print(
            "StoryService: updateChapter response ${response.statusCode}, Body: ${response.body}");
      }
      if (response.statusCode == 200) {
        return Chapter.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error updating chapter $chapterId: $e');
      return null;
    }
  }

  Future<bool> deleteChapter(String chapterId) async {
    final String url = '$_baseUrl/deletechapter/$chapterId';
    if (kDebugMode) print("StoryService: DELETE $url (Delete Chapter)");
    try {
      final response = await http.delete(Uri.parse(url),
          headers: await _getHeaders(isDeleteOrPostNoBody: true));
      if (kDebugMode) {
        print(
            "StoryService: deleteChapter response ${response.statusCode}, Body: ${response.body}");
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('Error deleting chapter $chapterId: $e');
      return false;
    }
  }

  // Update Story Metadata
  Future<Story?> updateStory(Story storyMetadata) async {
    final String url = '$_baseUrl/updateStory/${storyMetadata.id}';
    final Map<String, dynamic> requestBody =
        _buildStoryRequestBody(storyMetadata, isCreate: false);

    // Re-validate UserID presence
    if (requestBody['UserID'] == null) {
      if (kDebugMode) {
        print(
            'StoryService Error: Valid UserID is required for updateStory. Payload value: ${requestBody['UserID']}. Original authorId: ${storyMetadata.authorId}');
      }
      return null;
    }
    // Ensure Story ID (ID) is present and valid for update
    if (!requestBody.containsKey('ID') ||
        requestBody['ID'] == null ||
        requestBody['ID'] == 0) {
      if (kDebugMode) {
        print(
            'StoryService Error: Story ID is missing or invalid in the request body for updateStory. Original story ID: ${storyMetadata.id}. Current ID in payload: ${requestBody['ID']}');
      }
      return null;
    }

    if (kDebugMode) {
      print(
          "StoryService: PUT $url (Update Story Metadata), Payload: ${jsonEncode(requestBody)}");
    }
    try {
      final response = await http.put(Uri.parse(url),
          headers: await _getHeaders(), body: jsonEncode(requestBody));
      if (kDebugMode) {
        print(
            "StoryService: updateStory (Metadata) response ${response.statusCode}, Body: ${response.body}");
      }
      if (response.statusCode == 200) {
        return Story.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        if (kDebugMode) {
          print(
              "Failed to update story metadata. Status: ${response.statusCode}, Body: ${response.body}");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error updating story metadata: $e');
      return null;
    }
  }

  // Get Story/Stories Methods
  Future<List<Story>> getStoriesByAuthor(String authorIdString) async {
    int? numericAuthorId = int.tryParse(authorIdString);
    if (numericAuthorId == null) {
      if (kDebugMode) {
        print(
            'StoryService Error: Non-numeric authorId for getStoriesByAuthor: $authorIdString');
      }
      return [];
    }
    final String url = '$_baseUrl/GetStoriesByUser/$numericAuthorId';
    if (kDebugMode) print("StoryService: GET $url");
    try {
      final response =
          await http.get(Uri.parse(url), headers: await _getHeaders());
      if (kDebugMode) {
        print(
            "StoryService: getStoriesByAuthor response ${response.statusCode}, Body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}");
      }
      if (response.statusCode == 200) {
        // Handle null or empty body
        if (response.body == null ||
            response.body.isEmpty ||
            response.body.toLowerCase() == 'null') {
          if (kDebugMode)
            print(
                "StoryService: getStoriesByAuthor received null or empty body for user $authorIdString.");
          return [];
        }
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((data) => Story.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load stories for user. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching stories for user: $e');
      throw Exception('Error fetching stories for user: $e');
    }
  }

  Future<List<Story>> getAllStories() async {
    final String url = '$_baseUrl/GetAllStories';
    if (kDebugMode) print("StoryService: GET $url");
    try {
      final response = await http.get(Uri.parse(url),
          headers: await _getHeaders(requireAuth: false));
      if (kDebugMode) {
        print(
            "StoryService: getAllStories response ${response.statusCode}, Body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}");
      }
      if (response.statusCode == 200) {
        // Handle null or empty body
        if (response.body == null ||
            response.body.isEmpty ||
            response.body.toLowerCase() == 'null') {
          if (kDebugMode)
            print("StoryService: getAllStories received null or empty body.");
          return [];
        }
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((data) => Story.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load all stories. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print("StoryService: Exception in getAllStories: $e");
      throw Exception('Error fetching all stories: $e');
    }
  }

  Future<Story?> getStoryById(int storyId) async {
    final String url = '$_baseUrl/GetStories/$storyId';
    if (kDebugMode) print("StoryService: GET $url (for single story details)");
    try {
      final response =
          await http.get(Uri.parse(url), headers: await _getHeaders());
      if (kDebugMode) {
        print(
            "StoryService: getStoryById response ${response.statusCode}, Body: ${response.body}");
      }
      if (response.statusCode == 200) {
        // Handle null or empty body
        if (response.body == null ||
            response.body.isEmpty ||
            response.body.toLowerCase() == 'null') {
          if (kDebugMode)
            print(
                "StoryService: getStoryById received null or empty body for story $storyId.");
          return null;
        }
        return Story.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        if (kDebugMode) {
          print(
              'Failed to load story $storyId. Status: ${response.statusCode}, Body: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching story $storyId: $e');
      return null;
    }
  }

  Future<bool> deleteStory(int storyId) async {
    final String url = '$_baseUrl/deleteStory/$storyId';
    if (kDebugMode) print("StoryService: DELETE $url");
    try {
      final response = await http.delete(Uri.parse(url),
          headers: await _getHeaders(isDeleteOrPostNoBody: true));
      if (kDebugMode) {
        print(
            "StoryService: deleteStory response ${response.statusCode}, Body: ${response.body}");
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('Error deleting story: $e');
      return false;
    }
  }

  // Like/View Methods
  Future<bool> incrementViewCount(int storyId) async {
    final Story? currentStory = await getStoryById(storyId);
    if (currentStory == null) {
      if (kDebugMode) {
        print(
            "StoryService Error: Could not fetch story $storyId to increment view count.");
      }
      return false;
    }
    // Use PUT with full body or PATCH with specific field based on API design
    // Assuming PATCH here for simplicity
    final Map<String, dynamic> patchData = {'Views': currentStory.views + 1};
    final String url =
        '$_baseUrl/updateStory/$storyId'; // Assuming update endpoint handles this

    if (kDebugMode) {
      print(
          "StoryService: PATCH $url (increment view), Payload: ${jsonEncode(patchData)}");
    }
    try {
      final response = await http.patch(Uri.parse(url),
          headers: await _getHeaders(), body: jsonEncode(patchData));
      if (kDebugMode) {
        print(
            "StoryService: incrementViewCount response ${response.statusCode}, Body: ${response.body}");
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing view count for story $storyId: $e');
      }
      return false;
    }
  }

  Future<bool> likeStory(int storyId) async {
    final Story? currentStory = await getStoryById(storyId);
    if (currentStory == null) {
      if (kDebugMode)
        print("StoryService Error: Could not fetch story $storyId to like.");
      return false;
    }
    final Map<String, dynamic> patchData = {'Likes': currentStory.likes + 1};
    final String url =
        '$_baseUrl/updateStory/$storyId'; // Assuming update endpoint

    if (kDebugMode)
      print(
          "StoryService: PATCH $url (like story), Payload: ${jsonEncode(patchData)}");
    try {
      final response = await http.patch(Uri.parse(url),
          headers: await _getHeaders(), body: jsonEncode(patchData));
      if (kDebugMode)
        print(
            "StoryService: likeStory response ${response.statusCode}, Body: ${response.body}");
      // Check for common success codes
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('Error liking story $storyId: $e');
      return false;
    }
  }

  Future<bool> unlikeStory(int storyId) async {
    final Story? currentStory = await getStoryById(storyId);
    if (currentStory == null) {
      if (kDebugMode)
        print("StoryService Error: Could not fetch story $storyId to unlike.");
      return false;
    }
    if (currentStory.likes <= 0) {
      if (kDebugMode)
        print(
            "StoryService Info: Story $storyId already has 0 likes. Cannot unlike further.");
      return true; // Operation is logically successful (state is already 0)
    }
    final Map<String, dynamic> patchData = {
      'Likes': max(0, currentStory.likes - 1)
    };
    final String url =
        '$_baseUrl/updateStory/$storyId'; // Assuming update endpoint

    if (kDebugMode)
      print(
          "StoryService: PATCH $url (unlike story), Payload: ${jsonEncode(patchData)}");
    try {
      final response = await http.patch(Uri.parse(url),
          headers: await _getHeaders(), body: jsonEncode(patchData));
      if (kDebugMode)
        print(
            "StoryService: unlikeStory response ${response.statusCode}, Body: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('Error unliking story $storyId: $e');
      return false;
    }
  }

  Future<bool> getLikeStatus(int storyId) async {
    // This likely requires a dedicated endpoint or the info included in getStoryById
    // Assuming getStoryById includes 'CurrentUserHasLiked' as before
    final Story? story = await getStoryById(storyId);
    if (story != null) {
      // Placeholder: Need to adjust Story.fromJson if 'CurrentUserHasLiked' exists
      // Example: bool currentUserHasLiked = story.currentUserHasLiked ?? false;
      // For now, returning false as it's not explicitly in the Story model provided
      if (kDebugMode)
        print(
            "StoryService: getLikeStatus relies on 'CurrentUserHasLiked' field in Story response, which might be missing.");
      return false;
    }
    if (kDebugMode)
      print("StoryService: Failed to get story $storyId for like status.");
    return false;
  }

  // --- Collaborator Methods ---

  /// Fetches the list of collaborators (as Author objects) for a given story.
  Future<List<Author>> getCollaboratorsByStory(int storyId) async {
    final String url = '$_baseUrl/GetCollaboratorByStory/$storyId';
    if (kDebugMode) print("StoryService: GET $url (Fetch Collaborators)");
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true), // Assuming auth needed
      );

      if (kDebugMode) {
        print(
            "StoryService: getCollaboratorsByStory response ${response.statusCode}, Body: ${response.body}");
      }

      if (response.statusCode == 200) {
        // --- FIX: Handle null or empty body ---
        if (response.body == null ||
            response.body.isEmpty ||
            response.body.toLowerCase() == 'null') {
          // If body is null, empty, or the string "null", return an empty list
          if (kDebugMode) {
            print(
                "StoryService: getCollaboratorsByStory received null or empty body for story $storyId. Returning empty list.");
          }
          return []; // Return an empty list gracefully
        }
        // --- END FIX ---

        // If body is valid JSON (not null/empty), proceed with decoding
        final List<dynamic> responseData = jsonDecode(response.body);

        // The rest of the parsing logic
        return responseData
            .map((data) {
              try {
                // Ensure data is actually a map before parsing
                if (data is Map<String, dynamic>) {
                  return Author.fromJson(data);
                } else {
                  if (kDebugMode)
                    print("Skipping invalid item in collaborator list: $data");
                  return null;
                }
              } catch (e) {
                if (kDebugMode)
                  print("Error parsing collaborator item: $data. Error: $e");
                return null; // Skip items that cause parsing errors
              }
            })
            .whereType<
                Author>() // Filter out nulls from failed parsing or invalid items
            .toList();
      } else {
        // Handle API errors (e.g., 404 Not Found, 500 Server Error)
        if (kDebugMode) {
          print(
              'Failed to load collaborators for story $storyId. Status: ${response.statusCode}, Body: ${response.body}');
        }
        // Throw an exception that the ViewModel can catch
        throw Exception(
            'Failed to load collaborators (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode)
        print('Error fetching collaborators for story $storyId: $e');
      // Re-throw the exception so the ViewModel knows about the failure
      throw Exception('Error fetching collaborators: $e');
    }
  }

  /// Adds a collaborator to a story by their email.
  Future<bool> addCollaborator(int storyId, String email) async {
    const String url = '$_baseUrl/createcollaborator';
    final Map<String, dynamic> requestBody = {
      "story_id": storyId,
      "email": email.trim(), // Ensure email is trimmed
    };

    if (kDebugMode) {
      print("StoryService: POST $url, Payload: ${jsonEncode(requestBody)}");
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true), // Auth needed
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print(
            "StoryService: addCollaborator response ${response.statusCode}, Body: ${response.body}");
      }

      // Check for successful status codes (200 OK or 201 Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // Successfully added
      } else {
        // Handle potential errors (e.g., user not found, already collaborator)
        try {
          final responseData = jsonDecode(response.body);
          final message = responseData['message'] ??
              responseData['error'] ??
              'Failed to add collaborator.';
          if (kDebugMode) print('API Error adding collaborator: $message');
          // Consider throwing a specific exception based on message if needed
          // throw Exception('Failed to add collaborator: $message');
        } catch (e) {
          if (kDebugMode)
            print('Failed to parse error response: ${response.body}');
          // throw Exception('Failed to add collaborator.');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error adding collaborator: $e');
      // Re-throw or handle specific network errors
      // throw Exception('Network error adding collaborator: $e');
      return false;
    }
  }

  /// Removes a collaborator from a story.
  Future<bool> removeCollaborator(int storyId, int userIdToRemove) async {
    const String url = '$_baseUrl/deletecollaborator';
    final Map<String, dynamic> requestBody = {
      "story_id": storyId,
      "user_id": userIdToRemove,
    };

    if (kDebugMode) {
      print("StoryService: DELETE $url, Payload: ${jsonEncode(requestBody)}");
    }

    try {
      // Use http.delete, but pass headers and body as the API expects it
      final response = await http.delete(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: true), // Auth needed
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print(
            "StoryService: removeCollaborator response ${response.statusCode}, Body: ${response.body}");
      }

      // Check for successful status codes (200 OK or 204 No Content)
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true; // Successfully removed
      } else {
        if (kDebugMode)
          print(
              'API Error removing collaborator: Status ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error removing collaborator: $e');
      return false;
    }
  }
} // End of StoryService class
