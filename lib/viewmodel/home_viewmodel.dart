// viewmodel/home_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/services/story_service.dart';
import 'package:collabwrite/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  List<String> filters = ["+", "Trending", "Genres", "Collaboration"];
  int selectedFilter = 1; // Default to "Trending"

  List<Story> _allFetchedStories = []; // Store all stories fetched from API
  List<Story> _displayedStories = []; // Stories to be displayed after filtering
  List<Story> get stories => List.unmodifiable(_displayedStories);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentUserId;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  final StoryService _storyService = StoryService();
  final AuthService _authService = AuthService();

  HomeViewModel() {
    if (kDebugMode) print("HomeViewModel: Constructor - Initiating data load.");
    // Initiate data loading when the ViewModel is created.
    // This is an async call, but it manages its own state updates (_isLoading, notifyListeners).
    loadCurrentUserAndFetchStories();
  }

  Future<void> loadCurrentUserAndFetchStories(
      {bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh && _allFetchedStories.isNotEmpty) {
      if (kDebugMode)
        print(
            "HomeViewModel: Skipping loadCurrentUserAndFetchStories, already processing or data exists and not forced.");
      return;
    }
    if (kDebugMode)
      print(
          "HomeViewModel: loadCurrentUserAndFetchStories called. forceRefresh: $forceRefresh");

    _isLoading = true;
    _errorMessage = null; // Clear previous errors on new load attempt
    // Notify listeners for initial loading state or if it's a user-triggered refresh
    if (!forceRefresh || _allFetchedStories.isEmpty) {
      notifyListeners();
    }

    try {
      _currentUserId = await _authService.getCurrentUserId();
      if (kDebugMode) print("HomeViewModel: Current User ID: $_currentUserId");
      await fetchStories(forceRefresh: forceRefresh);
    } catch (e) {
      if (kDebugMode) print("HomeViewModel: Error loading current user ID: $e");
      _errorMessage = "Failed to identify current user. $e";
      _isLoading = false;
      _applyFilters(); // Apply filters even on error to clear stories if needed
      notifyListeners();
    }
    // fetchStories will handle its own isLoading and notifyListeners upon completion/error.
  }

  Future<void> fetchStories({bool forceRefresh = false}) async {
    if (kDebugMode)
      print("HomeViewModel: fetchStories called. forceRefresh: $forceRefresh");
    // _isLoading is already true from loadCurrentUserAndFetchStories or a direct call to refresh.
    // If called directly (e.g. pull-to-refresh), ensure isLoading is set.
    if (!_isLoading) {
      _isLoading = true;
      _errorMessage = null;
      if (!forceRefresh && stories.isEmpty) {
        notifyListeners();
      }
    }

    try {
      if (kDebugMode)
        print("HomeViewModel: Attempting to fetch all stories from service...");
      final fetchedStories = await _storyService.getAllStories();
      _allFetchedStories = fetchedStories;
      if (kDebugMode)
        print(
            "HomeViewModel: Successfully fetched ${_allFetchedStories.length} stories.");
      _errorMessage = null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("HomeViewModel: Error fetching stories: $e");
        print("HomeViewModel: StackTrace: $stackTrace");
      }
      _errorMessage = "Failed to load stories. Error: ${e.toString()}";
      _allFetchedStories = []; // Clear stories on error
    } finally {
      _applyFilters(); // Apply all current filters (user, search, etc.) to the fetched data
      _isLoading = false;
      if (kDebugMode) {
        print(
            "HomeViewModel: fetchStories finished. isLoading: $_isLoading, Displayed Stories: ${_displayedStories.length}, Error: $_errorMessage");
      }
      notifyListeners();
    }
  }

  void _applyFilters() {
    List<Story> filtered = List.from(_allFetchedStories);

    // 1. Apply user filter (don't show current user's stories)
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      filtered = filtered.where((story) {
        // Ensure story.authorId is correctly parsed/compared as String
        // Assuming story.authorId is String, and _currentUserId is String
        return story.authorId.toString() != _currentUserId;
      }).toList();
      if (kDebugMode)
        print(
            "HomeViewModel: Applied user filter (exclude user ID: $_currentUserId). Count after user filter: ${filtered.length}");
    } else {
      if (kDebugMode)
        print("HomeViewModel: No current user ID, skipping user filter.");
    }

    // 2. Apply search filter
    if (_searchQuery.isNotEmpty) {
      String lowerCaseQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((story) {
        return story.title.toLowerCase().contains(lowerCaseQuery) ||
                story.description!.toLowerCase().contains(lowerCaseQuery)
            // Consider adding author name if available and searchable
            ;
      }).toList();
      if (kDebugMode)
        print(
            "HomeViewModel: Applied search filter '$_searchQuery'. Count after search filter: ${filtered.length}");
    }

    // 3. Apply other filters (e.g., "Trending", "Genres")
    // This is where you'd add logic if 'filters[selectedFilter]' implies more than just UI state.
    // For now, it's not changing the data further beyond user and search.
    // Example: if (filters[selectedFilter] == "Trending") { /* sort by views/likes or fetch specific trending endpoint */ }

    _displayedStories = filtered;
    if (kDebugMode)
      print(
          "HomeViewModel: Total displayed stories after all filters: ${_displayedStories.length}");
  }

  void updateSearchQuery(String query) {
    if (_searchQuery != query.trim()) {
      _searchQuery = query.trim();
      if (kDebugMode)
        print("HomeViewModel: Search query updated to: '$_searchQuery'");
      _applyFilters();
      notifyListeners();
    }
  }

  void selectFilter(int index) {
    if (selectedFilter != index) {
      selectedFilter = index;
      if (kDebugMode)
        print("HomeViewModel: Filter selected: ${filters[index]}");
      // TODO: Implement actual filtering logic based on 'Trending', 'Genres' etc.
      // This might involve re-fetching data or further filtering _allFetchedStories.
      _applyFilters(); // Re-apply all filters including the new selection if it affects data
      notifyListeners();
    }
  }

  Future<void> refreshHomeScreenData() async {
    if (kDebugMode) print("HomeViewModel: refreshHomeScreenData called.");
    // Re-fetch current user ID and then stories, forcing a refresh.
    await loadCurrentUserAndFetchStories(forceRefresh: true);
  }
}
