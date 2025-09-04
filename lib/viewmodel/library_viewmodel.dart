import 'package:flutter/material.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/services/story_service.dart';
import 'package:collabwrite/services/auth_service.dart';
import 'package:flutter/foundation.dart';

enum StorySortOption { lastEditedDesc, lastEditedAsc, titleAsc, titleDesc }

class LibraryViewModel extends ChangeNotifier {
  List<Story> _allStories = [];
  List<Story> _filteredStories = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSearchActive = false;
  String _searchQuery = '';

  Set<StoryStatus> _selectedStatuses = {};
  Set<String> _selectedTypes = {};
  StorySortOption _sortOption = StorySortOption.lastEditedDesc;

  final StoryService _storyService = StoryService();
  final AuthService _authService = AuthService();

  List<Story> get filteredStories => List.unmodifiable(_filteredStories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSearchActive => _isSearchActive;
  String get searchQuery => _searchQuery;
  Set<StoryStatus> get selectedStatuses => Set.unmodifiable(_selectedStatuses);
  Set<String> get selectedTypes => Set.unmodifiable(_selectedTypes);
  StorySortOption get sortOption => _sortOption;

  LibraryViewModel() {
    // loadStories(); // Called from LibraryScreen initState
  }

  Future<void> loadStories({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) {
      if (kDebugMode)
        print(
            "LibraryViewModel: Already loading, refresh not forced. Skipping.");
      return;
    }
    if (kDebugMode)
      print(
          "LibraryViewModel: loadStories called. forceRefresh: $forceRefresh");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? userId;
    try {
      userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _errorMessage =
            "User not logged in. Please log in to view your library.";
        if (kDebugMode) print("LibraryViewModel: User not logged in.");
        _allStories = [];
        _filteredStories = [];
        return; // Finally block will handle _isLoading and notifyListeners
      }

      if (kDebugMode)
        print("LibraryViewModel: Fetching stories for user $userId...");
      _allStories = await _storyService.getStoriesByAuthor(userId);
      if (kDebugMode)
        print(
            "LibraryViewModel: Successfully fetched ${_allStories.length} stories for user $userId.");
      _applyFiltersAndSort();
      _errorMessage = null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("LibraryViewModel: Error loading stories for user $userId: $e");
        print("LibraryViewModel: StackTrace: $stackTrace");
      }
      _errorMessage =
          "Failed to load stories. Please try again. Error: ${e.toString()}";
      _allStories = [];
      _filteredStories = [];
    } finally {
      _isLoading = false;
      if (kDebugMode)
        print(
            "LibraryViewModel: loadStories finished. isLoading: $_isLoading, Stories: ${_allStories.length}");
      notifyListeners();
    }
  }

  void toggleSearch() {
    _isSearchActive = !_isSearchActive;
    if (!_isSearchActive) _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFiltersAndSort();
      notifyListeners();
    }
  }

  void applyFilters({
    required Set<StoryStatus> statuses,
    required Set<String> types,
    required StorySortOption sort,
  }) {
    _selectedStatuses = statuses;
    _selectedTypes = types;
    _sortOption = sort;
    _applyFiltersAndSort();
    notifyListeners();
    if (kDebugMode)
      print(
          "LibraryViewModel: Filters applied. Statuses: $_selectedStatuses, Types: $_selectedTypes, Sort: $_sortOption");
  }

  void _applyFiltersAndSort() {
    List<Story> filtered = List.from(_allStories);
    if (_isSearchActive && _searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((story) {
        return story.title.toLowerCase().contains(query) ||
            (story.description?.toLowerCase().contains(query) ?? false) ||
            story.genres.any((genre) => genre.toLowerCase().contains(query)) ||
            story.authorName.toLowerCase().contains(query);
      }).toList();
    }
    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered
          .where((story) => _selectedStatuses.contains(story.status))
          .toList();
    }
    if (_selectedTypes.isNotEmpty) {
      filtered = filtered
          .where((story) => _selectedTypes.contains(story.storyType))
          .toList();
    }
    switch (_sortOption) {
      case StorySortOption.lastEditedDesc:
        filtered.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
        break;
      case StorySortOption.lastEditedAsc:
        filtered.sort((a, b) => a.lastEdited.compareTo(b.lastEdited));
        break;
      case StorySortOption.titleAsc:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case StorySortOption.titleDesc:
        filtered.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }
    _filteredStories = filtered;
    if (kDebugMode)
      print(
          "LibraryViewModel: _applyFiltersAndSort completed. Filtered stories: ${_filteredStories.length}, All stories: ${_allStories.length}");
  }

  Future<bool> deleteStory(int storyId) async {
    if (kDebugMode)
      print("LibraryViewModel: Attempting to delete story: $storyId");
    bool success = false;
    _errorMessage = null; // Clear previous errors

    try {
      success = await _storyService.deleteStory(storyId);
      if (success) {
        _allStories.removeWhere((story) => story.id == storyId);
        _applyFiltersAndSort();
        if (kDebugMode)
          print(
              "LibraryViewModel: Story $storyId deleted successfully (API & local).");
      } else {
        _errorMessage = "API failed to delete story $storyId.";
        if (kDebugMode)
          print("LibraryViewModel: API failed to delete story $storyId.");
      }
    } catch (e) {
      _errorMessage = "Error deleting story $storyId: $e";
      if (kDebugMode)
        print("LibraryViewModel: Exception deleting story $storyId: $e");
      success = false;
    } finally {
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateStoryStatus(int storyId, StoryStatus newStatus) async {
    if (kDebugMode)
      print(
          "LibraryViewModel: Attempting to update status for story $storyId to $newStatus");
    _errorMessage = null;

    Story? storyToUpdate = _allStories.firstWhere((s) => s.id == storyId,
        orElse: () => throw Exception("Story not found locally"));

    Story storyWithNewStatus = storyToUpdate.copyWith(
      status: newStatus,
      lastEdited: DateTime.now(),
    );

    try {
      Story? updatedStoryFromApi =
          await _storyService.updateStory(storyWithNewStatus);

      if (updatedStoryFromApi != null) {
        final index = _allStories.indexWhere((s) => s.id == storyId);
        if (index != -1) {
          _allStories[index] = updatedStoryFromApi;
          _applyFiltersAndSort();
          if (kDebugMode)
            print(
                "LibraryViewModel: Story $storyId status updated to $newStatus (API & local).");
          return true;
        } else {
          _errorMessage =
              "Error: Story $storyId found locally but not after API update.";
          return false;
        }
      } else {
        _errorMessage = "API failed to update status for story $storyId.";
        if (kDebugMode)
          print(
              "LibraryViewModel: API failed to update status for story $storyId.");
        return false;
      }
    } catch (e) {
      _errorMessage = "Error updating story $storyId status: $e";
      if (kDebugMode)
        print("LibraryViewModel: Exception updating story $storyId status: $e");
      return false;
    } finally {
      notifyListeners();
    }
  }
}
