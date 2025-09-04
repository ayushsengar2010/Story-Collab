// viewmodel/story_reader_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/data/models/user_model.dart'
    as app_user; // Use alias for UI User model
import 'package:collabwrite/data/models/author_model.dart'
    as author_model; // Import Author model from backend
import 'package:collabwrite/services/story_service.dart';
import 'package:collabwrite/services/user_service.dart'; // Import UserService
import 'package:collabwrite/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StoryReaderViewModel extends ChangeNotifier {
  // Use the Story model that includes Chapters
  Story _story;
  app_user.User?
      _author; // Holds the author details in the UI User model format
  String _storyContent = ''; // Holds the formatted content to display
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLiked = false;
  int _likesCount;
  int _viewsCount;
  bool _isFollowingAuthor = false; // Placeholder state for following
  bool _isSaved = false;

  final StoryService _storyService = StoryService();
  final UserService _userService = UserService(); // Add UserService
  final AuthService _authService = AuthService();

  StoryReaderViewModel({required Story story})
      : _story = story, // Initialize with the passed story
        _likesCount = story.likes,
        _viewsCount = story.views {
    initialize(); // Start fetching additional data
  }

  // --- Getters ---
  Story get story => _story; // Expose the potentially updated story object
  app_user.User? get author => _author;
  String get storyContent => _storyContent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLiked => _isLiked;
  int get likesCount => _likesCount;
  int get viewsCount => _viewsCount;
  bool get isFollowingAuthor => _isFollowingAuthor;
  bool get isSaved => _isSaved;

  // --- Initialization ---
  Future<void> initialize() async {
    if (kDebugMode)
      print("StoryReaderViewModel: Initializing for story ID ${_story.id}");
    _isLoading = true;
    _errorMessage = null;
    // Don't notify listeners yet, wait until initial fetches complete or fail

    try {
      // Parallelize non-dependent fetches
      final futures = <Future>[
        _checkIfSaved(_story.id),
        _storyService.getLikeStatus(_story.id),
        _fetchAuthorDetails(_story.authorId), // Fetch author details
        _fetchAndFormatContent(), // Fetch and format content
        _storyService
            .incrementViewCount(_story.id), // Increment view (fire and forget)
      ];

      // Await essential results
      final results = await Future.wait(
          futures.sublist(0, 4)); // Wait for save, like, author, content
      _isSaved = results[0] as bool;
      _isLiked = results[1] as bool;
      // _author is set within _fetchAuthorDetails
      // _storyContent is set within _fetchAndFormatContent

      if (kDebugMode) {
        print("StoryReaderViewModel: Initial save status: $_isSaved");
        print("StoryReaderViewModel: Initial like status: $_isLiked");
      }

      // Fetch fresh story stats *after* view increment might have processed
      final Story? freshStory = await _storyService.getStoryById(_story.id);
      if (freshStory != null) {
        // Update local story object and counts
        _story = freshStory;
        _likesCount = freshStory.likes;
        _viewsCount = freshStory.views;
        if (kDebugMode)
          print(
              "StoryReaderViewModel: Fetched fresh story stats. Likes: $_likesCount, Views: $_viewsCount");
      } else {
        if (kDebugMode)
          print(
              "StoryReaderViewModel: Could not fetch fresh story details for ${_story.id}. Using initial stats.");
        // Keep the initial counts from the constructor if fetch fails
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("StoryReaderViewModel: Error during initialization: $e");
        print("StackTrace: $stackTrace");
      }
      _errorMessage = "Could not load story details. Please try again.";
      // Ensure content shows error if loading failed
      if (_storyContent.isEmpty) {
        _storyContent = "Error loading content.";
      }
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI after all initial loading/fetching
    }
  }

  // --- Helper Methods for Initialization ---

  Future<bool> _checkIfSaved(int storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStoriesJson = prefs.getString('saved_stories');
      if (savedStoriesJson == null) return false;
      final List<dynamic> savedStoryIds = jsonDecode(savedStoriesJson);
      return savedStoryIds.cast<int>().contains(storyId);
    } catch (e) {
      if (kDebugMode) print("Error checking saved status: $e");
      return false; // Default to not saved on error
    }
  }

  Future<void> _fetchAuthorDetails(String authorIdString) async {
    if (authorIdString == "0" || authorIdString.isEmpty) {
      if (kDebugMode)
        print(
            "StoryReaderViewModel: Invalid authorId ('$authorIdString'), skipping author fetch.");
      _author = null;
      return;
    }
    try {
      // Fetch author details using UserService
      final author_model.Author fetchedAuthor =
          await _userService.getAuthorById(authorIdString);

      // Convert the Author model from the service to the app_user.User model for the UI
      _author = app_user.User(
        // Ensure ID conversion matches UI model (assuming UI uses int ID)
        id: fetchedAuthor.id,
        name: fetchedAuthor.name,
        bio: fetchedAuthor.bio,
        profileImage: fetchedAuthor.profileImage,
        location: fetchedAuthor.location ?? '',
        website: fetchedAuthor.website,
        followers: fetchedAuthor.followers,
        following: fetchedAuthor.following,
        stories: fetchedAuthor.storiesCount,
        isVerified: fetchedAuthor.isVerified,
      );
      if (kDebugMode)
        print(
            "StoryReaderViewModel: Fetched author details for ID $authorIdString: ${_author?.name}");
    } catch (e) {
      if (kDebugMode)
        print(
            "StoryReaderViewModel: Error fetching author details for ID $authorIdString: $e");
      _author = null; // Set author to null if fetch fails
    }
    // No notifyListeners here, initialization handles it at the end
  }

  Future<void> _fetchAndFormatContent() async {
    try {
      if (_story.chapters.isNotEmpty) {
        // Check if content is already present (e.g., passed from LibraryScreen)
        bool contentMissing = _story.chapters.any((c) => c.content.isEmpty);

        if (!contentMissing) {
          // If all chapters have content, just format it
          _formatChapterContent();
          if (kDebugMode)
            print("StoryReaderViewModel: Using pre-loaded chapter content.");
          return;
        }

        // If content is missing, fetch chapters again (or individually)
        if (kDebugMode)
          print(
              "StoryReaderViewModel: Content missing, fetching chapters for story ${_story.id}");
        List<Chapter> fetchedChapters =
            await _storyService.getChaptersByStory(_story.id);
        if (fetchedChapters.isNotEmpty) {
          // Update the story object with fetched chapters
          _story = _story.copyWith(chapters: fetchedChapters);
          _formatChapterContent(); // Format the fetched content
          if (kDebugMode)
            print(
                "StoryReaderViewModel: Fetched and formatted ${fetchedChapters.length} chapters.");
        } else {
          if (kDebugMode)
            print(
                "StoryReaderViewModel: No chapters found when fetching content.");
          _storyContent =
              _story.description ?? "Content not available."; // Fallback
        }
      } else {
        // If story has no chapters array, use description as fallback
        if (kDebugMode)
          print(
              "StoryReaderViewModel: Story has no chapters array. Using description.");
        _storyContent =
            _story.description ?? "No content available for this story.";
      }
    } catch (e) {
      if (kDebugMode)
        print("StoryReaderViewModel: Error fetching/formatting content: $e");
      _storyContent = "Error loading content.";
    }
    // No notifyListeners here, initialization handles it at the end
  }

  void _formatChapterContent() {
    if (_story.chapters.isEmpty) {
      _storyContent = _story.description ?? "No content available.";
      return;
    }

    // Format based on story type
    if (_story.storyType.toLowerCase() == "single story" ||
        _story.chapters.length == 1) {
      // For single story, just use the content of the first chapter
      _storyContent = _story.chapters.first.content;
    } else {
      // For chapter-based, concatenate with titles
      _storyContent = _story.chapters
          .map((c) =>
              "## ${c.title}\n\n${c.content}\n\n---\n\n") // Add Markdown heading and separator
          .join();
    }
  }

  // --- Actions ---

  Future<void> toggleLike() async {
    if (kDebugMode)
      print(
          "StoryReaderViewModel: toggleLike called. Current _isLiked: $_isLiked");

    final originalIsLiked = _isLiked;
    final originalLikesCount = _likesCount;

    // Optimistic UI update
    _isLiked = !_isLiked;
    _likesCount =
        _isLiked ? originalLikesCount + 1 : max(0, originalLikesCount - 1);
    notifyListeners();

    bool success;
    try {
      if (_isLiked) {
        // If we are now liking it
        success = await _storyService.likeStory(_story.id);
      } else {
        // If we are now unliking it
        success = await _storyService.unlikeStory(_story.id);
      }

      if (!success) {
        // Revert UI if API call failed
        _isLiked = originalIsLiked;
        _likesCount = originalLikesCount;
        _errorMessage = "Could not update like status.";
        if (kDebugMode)
          print(
              "StoryReaderViewModel: Failed to update like status via API. Reverted UI.");
      } else {
        _errorMessage = null; // Clear previous errors on success
        if (kDebugMode)
          print(
              "StoryReaderViewModel: Like status updated successfully via API. Liked: $_isLiked, Count: $_likesCount");
      }
    } catch (e) {
      // Revert UI on exception
      _isLiked = originalIsLiked;
      _likesCount = originalLikesCount;
      _errorMessage = "Error updating like status: ${e.toString()}";
      if (kDebugMode)
        print("StoryReaderViewModel: Exception in toggleLike: $e");
    } finally {
      notifyListeners(); // Notify UI of final state (success or revert)
    }
  }

  Future<void> toggleSaveStory() async {
    if (kDebugMode)
      print(
          "StoryReaderViewModel: toggleSaveStory called. Current _isSaved: $_isSaved");

    final originalIsSaved = _isSaved;
    _isSaved = !_isSaved; // Toggle state optimistically
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      List<int> savedStoryIds = [];
      final savedStoriesJson = prefs.getString('saved_stories');

      if (savedStoriesJson != null) {
        try {
          // Ensure casting happens correctly
          savedStoryIds = List<int>.from(jsonDecode(savedStoriesJson) as List);
        } catch (e) {
          if (kDebugMode)
            print("Error decoding saved_stories JSON: $e. Resetting list.");
          savedStoryIds = []; // Reset if JSON is corrupt
        }
      }

      if (_isSaved) {
        // If saving
        if (!savedStoryIds.contains(_story.id)) {
          savedStoryIds.add(_story.id);
        }
      } else {
        // If unsaving
        savedStoryIds.remove(_story.id);
      }

      await prefs.setString('saved_stories', jsonEncode(savedStoryIds));
      if (kDebugMode)
        print(
            "StoryReaderViewModel: Updated saved stories in SharedPreferences: $savedStoryIds");
      _errorMessage = null; // Clear error on success
    } catch (e) {
      _isSaved = originalIsSaved; // Revert UI on error
      _errorMessage = "Error updating saved status: ${e.toString()}";
      if (kDebugMode)
        print("StoryReaderViewModel: Error in toggleSaveStory persistence: $e");
      notifyListeners(); // Notify UI of reverted state
    }
    // No final notifyListeners needed here as it's done optimistically and on error
  }

  // Placeholder for follow logic - needs backend implementation
  Future<void> toggleFollowAuthor() async {
    if (_author == null) return;

    final originalFollowState = _isFollowingAuthor;
    _isFollowingAuthor = !_isFollowingAuthor;
    notifyListeners(); // Optimistic UI update

    if (kDebugMode)
      print(
          "StoryReaderViewModel: Toggling follow for author ${_author!.id}. New state: $_isFollowingAuthor");

    // --- TODO: Add API call to follow/unfollow ---
    // bool success = await _userService.followAuthor(_author!.id, follow: _isFollowingAuthor);
    // if (!success) {
    //    _isFollowingAuthor = originalFollowState; // Revert on failure
    //    _errorMessage = "Could not update follow status.";
    //    notifyListeners();
    // } else {
    //    _errorMessage = null;
    // }
    // --- End TODO ---
  }
}
