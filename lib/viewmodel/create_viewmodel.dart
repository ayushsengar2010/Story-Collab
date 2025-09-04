// viewmodel/create_viewmodel.dart
import 'dart:io';
// import 'dart:math'; // Not strictly needed for this timestamp approach unless adding randomness
import 'package:flutter/material.dart';
// FlutterSecureStorage or SharedPreferences not needed for this specific ID approach
import 'package:image_picker/image_picker.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/services/story_service.dart';
import 'package:collabwrite/services/auth_service.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class CreateViewModel extends ChangeNotifier {
  String _title = '';
  String _description = '';
  String _writingContent = '';
  String _selectedStoryType = 'Single Story';
  List<String> _selectedGenres = [];
  String? _coverImagePath;

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  int? _editingStoryId;
  String?
      _currentDraftChapterId; // To store the ID of the chapter being edited for "Single Story"
  String _authorName = "Current User"; // Store author name

  bool _isPickingImage = false;

  final StoryService _storyService = StoryService();
  final AuthService _authService = AuthService();

  String get title => _title;
  String get description => _description;
  String get writingContent => _writingContent;
  String get selectedStoryType => _selectedStoryType;
  List<String> get selectedGenres => List.unmodifiable(_selectedGenres);
  String? get coverImagePath => _coverImagePath;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  final List<String> availableStoryTypes = const [
    'Single Story',
    'Chapter-based',
    'Collaborative'
  ];
  final List<String> popularGenres = const [
    'Fiction',
    'Fantasy',
    'Adventure',
    'Romance',
    'Sci-Fi',
    'Mystery',
    'Thriller',
    'Horror',
    'Historical',
    'Non-Fiction'
  ];

  void initialize({Story? draftStory}) {
    if (draftStory != null) {
      _editingStoryId = draftStory.id;
      _title = draftStory.title;
      _description = draftStory.description ?? '';
      _authorName = draftStory.authorName;
      _selectedStoryType = draftStory.storyType;
      _selectedGenres = List.from(draftStory.genres);
      _coverImagePath = draftStory.coverImage;
      _hasUnsavedChanges = false;

      // Content and chapter ID will now be loaded separately or on demand for editing.
      // For simplicity, if CreateScreen is ONLY for NEW stories, this part is less critical.
      // If CreateScreen can still be entered for editing a "Single Story" draft that previously had content:
      if (draftStory.chapters.isNotEmpty) {
        // This chapter comes from the story object, if list view provided it.
        _currentDraftChapterId = draftStory.chapters.first.id;
        _writingContent =
            draftStory.chapters.first.content; // Pre-fill if available
        if (kDebugMode)
          print(
              "CreateVM.init: Pre-filled content from draftStory.chapters. ChapterID: $_currentDraftChapterId");
      } else {
        _currentDraftChapterId = null;
        _writingContent = '';
        if (kDebugMode)
          print(
              "CreateVM.init: No chapters in draftStory. Content will be empty or loaded later.");
      }
    } else {
      // ... new story defaults
      _editingStoryId = null;
      _currentDraftChapterId = null;
      _title = '';
      _description = '';
      _writingContent = '';
      _selectedStoryType = availableStoryTypes.first;
      _selectedGenres = [];
      _coverImagePath = null;
      _hasUnsavedChanges = false;
      _authorName = "Current User";
    }
    if (kDebugMode)
      print(
          "CreateViewModel: Initialized. Editing Story ID: $_editingStoryId. WritingContent empty: ${_writingContent.isEmpty}");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  int _generateTimestampBasedTemporaryId() {
    int newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (newId > 2147483647) newId = 2147483647;
    if (newId <= 0) newId = 1;
    if (kDebugMode)
      print(
          "CreateViewModel: Generated timestamp-based temporary story ID $newId");
    return newId;
  }

  void _setUnsavedChanges() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void setTitle(String value) {
    if (_title != value) {
      _title = value;
      _setUnsavedChanges();
    }
  }

  void setDescription(String value) {
    if (_description != value) {
      _description = value;
      _setUnsavedChanges();
    }
  }

  void setWritingContent(String value) {
    if (_writingContent != value) {
      _writingContent = value;
      _setUnsavedChanges();
    }
  }

  void selectStoryType(String type) {
    if (_selectedStoryType != type && availableStoryTypes.contains(type)) {
      _selectedStoryType = type;
      _setUnsavedChanges();
      notifyListeners();
    }
  }

  void toggleGenre(String genre) {
    _selectedGenres.contains(genre)
        ? _selectedGenres.remove(genre)
        : _selectedGenres.add(genre);
    _setUnsavedChanges();
    notifyListeners();
  }

  Future<void> pickCoverImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _coverImagePath = image.path;
        _setUnsavedChanges();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("CreateViewModel: Error picking image: $e");
    } finally {
      _isPickingImage = false;
    }
  }

  void removeCoverImage() {
    if (_coverImagePath != null) {
      _coverImagePath = null;
      _setUnsavedChanges();
      notifyListeners();
    }
  }

  Future<bool> saveDraft() async {
    if (title.trim().isEmpty) {
      if (kDebugMode)
        print("CreateViewModel: Title is required to save draft.");
      return false;
    }
    _isSaving = true;
    notifyListeners();

    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      _isSaving = false;
      notifyListeners();
      if (kDebugMode)
        print("CreateViewModel: User not logged in for saveDraft.");
      return false;
    }

    bool isUpdatingStoryMetadata =
        (_editingStoryId != null && _editingStoryId! > 0);
    int storyIdToUse = isUpdatingStoryMetadata
        ? _editingStoryId!
        : _generateTimestampBasedTemporaryId();

    Story storyMetadataPayload = Story(
      id: storyIdToUse, title: _title, description: _description,
      coverImage: _coverImagePath, authorId: userId, authorName: _authorName,
      lastEdited: DateTime.now(), storyType: _selectedStoryType,
      status: StoryStatus.draft, genres: _selectedGenres,
      chapters: [], // Chapters handled separately
    );

    Story? savedStoryMetadata;
    if (isUpdatingStoryMetadata) {
      savedStoryMetadata =
          await _storyService.updateStory(storyMetadataPayload);
    } else {
      savedStoryMetadata =
          await _storyService.createStory(storyMetadataPayload);
    }

    if (savedStoryMetadata == null) {
      if (kDebugMode) print("CreateVM: Failed to save/update story metadata.");
      _isSaving = false;
      notifyListeners();
      return false;
    }
    _editingStoryId =
        savedStoryMetadata.id; // Update with actual ID from backend

    // Now handle the chapter
    Chapter? savedChapter;
    if (_writingContent.trim().isNotEmpty) {
      if (_currentDraftChapterId != null) {
        // Update existing chapter
        // We need chapter number. For single story, it's always 1.
        // If this CreateScreen handles more complex scenarios, this needs thought.
        savedChapter = await _storyService.updateChapter(
            chapterId: _currentDraftChapterId!,
            storyId: _editingStoryId!,
            title: "Chapter 1", // Or derive from story title for single story
            content: _writingContent,
            chapterNumber: 1,
            isComplete: false);
      } else {
        // Create new chapter
        savedChapter = await _storyService.createChapter(
            storyId: _editingStoryId!,
            title: "Chapter 1", // Or derive from story title
            content: _writingContent,
            chapterNumber: 1,
            isComplete: false);
      }

      if (savedChapter == null) {
        if (kDebugMode)
          print(
              "CreateVM: Failed to save/update chapter content after story metadata.");
        // Metadata saved, but content failed. Partial success. UX decision needed.
      } else {
        _currentDraftChapterId =
            savedChapter.id; // Store new/updated chapter ID
      }
    }

    _isSaving = false;
    _hasUnsavedChanges = !(savedStoryMetadata != null &&
        (_writingContent.trim().isEmpty || savedChapter != null));
    notifyListeners();
    return _hasUnsavedChanges == false;
  }

  Future<bool> publishStory() async {
    if (title.trim().isEmpty ||
        writingContent.trim().isEmpty ||
        selectedGenres.isEmpty) {
      if (kDebugMode)
        print(
            "CreateViewModel: Title, content, and genres are required to publish.");
      return false;
    }
    _isSaving = true;
    notifyListeners();

    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      _isSaving = false;
      notifyListeners();
      if (kDebugMode)
        print("CreateViewModel: User not logged in for publishStory.");
      return false;
    }

    bool isUpdatingStoryMetadata = (_editingStoryId != null && _editingStoryId! > 0);
    int storyIdToUse = isUpdatingStoryMetadata ? _editingStoryId! : _generateTimestampBasedTemporaryId();

    Story storyMetadataPayload = Story(
      id: storyIdToUse, title: _title, description: _description,
      coverImage: _coverImagePath, authorId: userId, authorName: _authorName,
      lastEdited: DateTime.now(), publishedDate: DateTime.now(),
      storyType: _selectedStoryType, status: StoryStatus.published, genres: _selectedGenres,
      chapters: [],
    );

    Story? publishedStoryMetadata;
    if (isUpdatingStoryMetadata) {
      publishedStoryMetadata = await _storyService.updateStory(storyMetadataPayload);
    } else {
      publishedStoryMetadata = await _storyService.createStory(storyMetadataPayload);
    }

    if (publishedStoryMetadata == null) {
      if (kDebugMode) print("CreateVM: Failed to publish story metadata.");
      _isSaving = false; notifyListeners(); return false;
    }
    _editingStoryId = publishedStoryMetadata.id;

    Chapter? publishedChapter;
    if (_currentDraftChapterId != null) {
      publishedChapter = await _storyService.updateChapter(
          chapterId: _currentDraftChapterId!,
          storyId: _editingStoryId!,
          title: "Chapter 1", // Or story title
          content: _writingContent,
          chapterNumber: 1,
          isComplete: true);
    } else {
      publishedChapter = await _storyService.createChapter(
          storyId: _editingStoryId!,
          title: "Chapter 1", // Or story title
          content: _writingContent,
          chapterNumber: 1,
          isComplete: true);
    }

    if (publishedChapter == null) {
      if (kDebugMode) print("CreateVM: Failed to publish chapter content after story metadata.");
    }

    _isSaving = false;
    if (publishedStoryMetadata != null && publishedChapter != null) {
      _hasUnsavedChanges = false;
      _editingStoryId = null; // Clear after successful publish
      _currentDraftChapterId = null;
      if (kDebugMode) print("CreateVM: Story published successfully.");
    } else {
      if (kDebugMode) print("CreateVM: Failed to fully publish story and chapter.");
    }
    notifyListeners();
    return (publishedStoryMetadata != null && publishedChapter != null);
  }

  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  @override
  void dispose() {
    if (kDebugMode) print("CreateViewModel: Disposed");
    super.dispose();
  }
}
