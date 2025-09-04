import 'package:collabwrite/data/models/author_model.dart';
import 'package:flutter/material.dart';
import 'package:collabwrite/data/models/user_model.dart' as ui_user_model;
import 'package:collabwrite/data/models/story_model.dart' as data_story_model;
import 'package:collabwrite/services/auth_service.dart';
import 'package:collabwrite/services/user_service.dart';
import 'package:collabwrite/services/story_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StoryService _storyService = StoryService();

  ui_user_model.User? _user;
  List<data_story_model.Story> _userStories = [];
  List<data_story_model.Story> _collaborationStories = [];
  List<data_story_model.Story> _savedStories = [];
  bool _isLoading = true;
  String? _errorMessage;

  ui_user_model.User? get user => _user;
  List<data_story_model.Story> get userStories => _userStories;
  List<data_story_model.Story> get collaborationStories =>
      _collaborationStories;
  List<data_story_model.Story> get savedStories => _savedStories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProfileViewModel() {
    _initializeData();
  }

  Future<void> refresh() async {
    await _initializeData();
  }

  Future<void> _initializeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? currentUserId = await _authService.getCurrentUserId();

      if (currentUserId == null || currentUserId.isEmpty) {
        _errorMessage = "User not logged in. Please login again.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch user details
      final Author fetchedAuthor =
          await _userService.getAuthorById(currentUserId);

      // Fetch user's own stories
      _userStories = await _storyService.getStoriesByAuthor(currentUserId);

      // Count only published stories
      final int publishedStoriesCount = _userStories
          .where(
              (story) => story.status == data_story_model.StoryStatus.published)
          .length;

      if (kDebugMode) {
        print("ProfileViewModel: Fetched ${_userStories.length} stories, "
            "$publishedStoriesCount are published for user $currentUserId.");
      }

      _user = ui_user_model.User(
        id: fetchedAuthor.id,
        name: fetchedAuthor.name,
        bio: fetchedAuthor.bio,
        profileImage: fetchedAuthor.profileImage,
        location: fetchedAuthor.location ?? 'N/A',
        website: fetchedAuthor.website,
        followers: fetchedAuthor.followers,
        following: fetchedAuthor.following,
        stories: publishedStoriesCount, // Use the computed count
        isVerified: fetchedAuthor.isVerified,
      );

      // Fetch saved stories from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedStoriesJson = prefs.getString('saved_stories');
      List<int> savedStoryIds = [];
      if (savedStoriesJson != null) {
        savedStoryIds =
            (jsonDecode(savedStoriesJson) as List<dynamic>).cast<int>();
      }

      _savedStories = [];
      for (int storyId in savedStoryIds) {
        final story = await _storyService.getStoryById(storyId);
        if (story != null) {
          _savedStories.add(story);
        } else {
          if (kDebugMode) {
            print(
                "ProfileViewModel: Failed to fetch saved story with ID $storyId");
          }
        }
      }
      if (kDebugMode) {
        print(
            "ProfileViewModel: Loaded saved stories: ${_savedStories.length}");
      }

      // TODO: Implement fetching collaboration stories
      _collaborationStories = _generateDummyCollaborationStories(currentUserId);
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing profile data: $e");
      }
      _errorMessage = "Failed to load profile data: ${e.toString()}";
      _user = null; // Ensure user is null on error
      _userStories = [];
      _savedStories = [];
      _collaborationStories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<data_story_model.Story> _generateDummyCollaborationStories(
      String currentUserId) {
    return [];
  }

  Future<void> toggleSaveStory(data_story_model.Story story) async {
    final isSaved = _savedStories.any((s) => s.id == story.id);
    final prefs = await SharedPreferences.getInstance();
    List<int> savedStoryIds = [];
    final savedStoriesJson = prefs.getString('saved_stories');
    if (savedStoriesJson != null) {
      savedStoryIds =
          (jsonDecode(savedStoriesJson) as List<dynamic>).cast<int>();
    }

    if (isSaved) {
      _savedStories.removeWhere((s) => s.id == story.id);
      savedStoryIds.remove(story.id);
    } else {
      _savedStories.add(story);
      if (!savedStoryIds.contains(story.id)) {
        savedStoryIds.add(story.id);
      }
    }

    await prefs.setString('saved_stories', jsonEncode(savedStoryIds));
    if (kDebugMode) {
      print("ProfileViewModel: Saved stories updated: $savedStoryIds");
    }
    notifyListeners();
  }
}
