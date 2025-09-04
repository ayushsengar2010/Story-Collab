// viewmodel/edit_story_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/services/story_service.dart'; // Import StoryService
import 'package:collabwrite/services/auth_service.dart'; // Import AuthService
import 'package:flutter/foundation.dart'; // for kDebugMode

class EditStoryViewModel extends ChangeNotifier {
  Story _originalStory; // Keep the original to compare for unsaved changes
  late Story _editableStory; // This is the story that gets modified
  late Chapter _editableChapter; // The specific chapter being edited
  late int _chapterIndex;

  late TextEditingController chapterTitleController;
  late TextEditingController contentController;

  final StoryService _storyService = StoryService();
  final AuthService _authService = AuthService();

  String get appBarTitle {
    String title = chapterTitleController.text.isNotEmpty
        ? chapterTitleController.text
        : "Untitled Chapter";
    if (_editableStory.storyType.toLowerCase() == "single story") {
      return _editableStory
          .title; // For single story, app bar shows story title
    }
    return 'Chapter ${_chapterIndex + 1}: $title';
  }

  String get storyTitle => _editableStory.title;
  String get chapterProgress =>
      _editableStory.chapters != null && _editableStory.chapters!.isNotEmpty
          ? 'Chapter ${_chapterIndex + 1}/${_editableStory.chapters!.length}'
          : 'Chapter 1/1'; // Fallback for single story potentially

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  bool _justSaved = false;
  bool get justSaved => _justSaved;

  Story get storyObjectForCollaboration => _editableStory;
  Story get currentStoryState =>
      _editableStory; // For returning to LibraryScreen

  int get wordCount {
    return contentController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
  }

  EditStoryViewModel({required Story story, required Chapter chapter})
      : _originalStory = story.copyWith() {
    _editableStory = story; // This will be mutated

    // Find the chapter in the story's list or assume the passed 'chapter' is the one.
    _chapterIndex =
        _editableStory.chapters.indexWhere((ch) => ch.id == chapter.id);

    if (_chapterIndex != -1) {
      _editableChapter =
          _editableStory.chapters[_chapterIndex]; // Use the one from the list
    } else {
      // This means the 'chapter' object passed was not found in 'story.chapters'.
      // This could happen if story.chapters was empty initially.
      // For a "Single Story", we might assume 'chapter' is the one to use.
      _editableChapter = chapter;
      if (_editableStory.chapters.isEmpty) {
        _editableStory.chapters
            .add(_editableChapter); // Add it to the story's list
        _chapterIndex = 0;
      } else {
        // This is an unusual state - chapter provided but not in story's list, and list not empty.
        // Default to first chapter or handle error.
        _editableChapter = _editableStory.chapters.first;
        _chapterIndex = 0;
        if (kDebugMode)
          print(
              "EditStoryVM Warning: Provided chapter not in story.chapters. Using first chapter from story.");
      }
      if (kDebugMode)
        print(
            "EditStoryVM: Chapter ID ${chapter.id} used directly or added. Index set to $_chapterIndex");
    }

    chapterTitleController =
        TextEditingController(text: _editableChapter.title);
    contentController = TextEditingController(text: _editableChapter.content);

    // If content is empty, try to load it (e.g., for "Single Story" where only metadata was passed)
    if (_editableChapter.content.isEmpty &&
        _editableChapter.id != 'temp_draft_ch' &&
        _editableChapter.id != 'temp_pub_ch' &&
        _editableChapter.id.isNotEmpty) {
      _loadChapterContent(_editableChapter.id);
    }

    chapterTitleController.addListener(_onTextChanged);
    contentController.addListener(_onTextChanged);
    if (kDebugMode) {
      print(
          "EditStoryVM Initialized: Story ID: ${_editableStory.id}, Chapter ID: ${_editableChapter.id}, Chapter Title: '${_editableChapter.title}'");
      print(
          "EditStoryVM Initialized: Chapter Content IS EMPTY: ${_editableChapter.content.isEmpty}");
    }
  }

  Future<void> _loadChapterContent(String chapterId) async {
    if (kDebugMode)
      print("EditStoryVM: Loading content for chapter ID: $chapterId");
    _isSaving = true;
    notifyListeners(); // Use _isSaving for loading indicator
    Chapter? fetchedChapter = await _storyService.getChapterById(chapterId);
    _isSaving = false;
    if (fetchedChapter != null) {
      _editableChapter = _editableChapter.copyWith(
          content: fetchedChapter.content,
          title: fetchedChapter.title); // Update current chapter
      contentController.text = fetchedChapter.content;
      chapterTitleController.text = fetchedChapter.title; // Sync title too
      // Update it in the story's list as well
      if (_chapterIndex >= 0 &&
          _chapterIndex < _editableStory.chapters.length) {
        _editableStory.chapters[_chapterIndex] = _editableChapter;
      }
      _hasUnsavedChanges =
          false; // Content is now loaded, not "unsaved" from user typing
      if (kDebugMode)
        print(
            "EditStoryVM: Loaded content for chapter ID: $chapterId. Content empty: ${fetchedChapter.content.isEmpty}");
    } else {
      if (kDebugMode)
        print("EditStoryVM: Failed to load content for chapter ID: $chapterId");
    }
    notifyListeners();
  }

  void refreshStoryAfterCollaboration(Story updatedStoryFromCollaboration) {
    _originalStory = updatedStoryFromCollaboration.copyWith();
    _editableStory = updatedStoryFromCollaboration;
    // Re-initialize controllers based on the current chapter in the updated story
    _chapterIndex = _editableStory.chapters
            ?.indexWhere((ch) => ch.id == _editableChapter.id) ??
        0;
    if (_chapterIndex != -1 &&
        _editableStory.chapters != null &&
        _editableStory.chapters!.isNotEmpty) {
      _editableChapter = _editableStory.chapters![_chapterIndex];
      chapterTitleController.text = _editableChapter.title;
      contentController.text = _editableChapter.content;
    }
    _hasUnsavedChanges = false; // Assume synced
    notifyListeners();
  }

  void _onTextChanged() {
    // More robust unsaved changes check:
    bool titleChanged = chapterTitleController.text != _editableChapter.title;
    bool contentChanged = contentController.text != _editableChapter.content;

    if (titleChanged || contentChanged) {
      if (!_hasUnsavedChanges) {
        _hasUnsavedChanges = true;
        if (_justSaved) {
          _justSaved = false;
        }
        notifyListeners();
      }
    } else {
      // If changes are reverted back to original, mark as no unsaved changes
      // This requires comparing to the original state of the chapter loaded,
      // or just simply let hasUnsavedChanges stay true once any change is made.
      // For simplicity, once true, it stays true until save.
    }

    // To update AppBar title dynamically if chapter title changes
    if (chapterTitleController.text != _editableChapter.title) {
      // Simpler check for app bar refresh
      notifyListeners();
    }
  }

  Future<bool> saveDraft() async {
    if (chapterTitleController.text.trim().isEmpty) {
      if (kDebugMode)
        print("EditStoryVM: Chapter title cannot be empty for saving draft.");
      return false;
    }
    if (!_hasUnsavedChanges && !_isSaving) {
      // If no changes and not already saving, nothing to do
      if (kDebugMode) print("EditStoryVM: No unsaved changes to save.");
      _justSaved =
          true; // Indicate "Saved" state even if no actual change occurred
      notifyListeners();
      return true;
    }

    _isSaving = true;
    _justSaved = false;
    notifyListeners();

    // Update Story Metadata (lastEdited)
    _editableStory = _editableStory.copyWith(
        lastEdited: DateTime.now(), status: StoryStatus.draft);
    Story? updatedStoryMeta = await _storyService.updateStory(_editableStory);

    if (updatedStoryMeta == null) {
      if (kDebugMode)
        print("EditStoryVM: Failed to update story metadata for draft.");
      _isSaving = false;
      notifyListeners();
      return false;
    }
    _editableStory = updatedStoryMeta; // Keep story metadata updated

    // Update Chapter
    Chapter? updatedChapter = await _storyService.updateChapter(
        chapterId: _editableChapter.id,
        storyId: _editableStory.id,
        title: chapterTitleController.text,
        content: contentController.text,
        chapterNumber:
            _chapterIndex + 1, // Or a more robust chapter_number logic
        isComplete: _editableChapter
            .isComplete // Draft doesn't change completion status unless intended
        );

    _isSaving = false;
    if (updatedChapter != null) {
      _editableChapter = updatedChapter; // Update with response
      // Update chapter in the story's list
      if (_chapterIndex >= 0 &&
          _chapterIndex < _editableStory.chapters.length) {
        _editableStory.chapters[_chapterIndex] = _editableChapter;
      } else if (_editableStory.chapters.isEmpty && _chapterIndex == 0) {
        _editableStory.chapters.add(_editableChapter);
      }

      _originalStory = _editableStory.copyWith(
          // Update baseline with new chapter state
          chapters:
              List.from(_editableStory.chapters.map((c) => c.copyWith())));
      _hasUnsavedChanges = false;
      _justSaved = true;
      if (kDebugMode)
        print(
            'EditStoryVM: Draft saved successfully (Chapter ID: ${updatedChapter.id}).');
    } else {
      if (kDebugMode)
        print('EditStoryVM: Failed to save chapter draft to backend.');
    }
    notifyListeners();
    return updatedChapter != null;
  }

  Future<bool> publishChanges() async {
    if (chapterTitleController.text.trim().isEmpty || contentController.text.trim().isEmpty) { return false; }
    _isSaving = true; _justSaved = false; notifyListeners();

    // Update Story Metadata (lastEdited, publishedDate, status)
    _editableStory = _editableStory.copyWith(
        lastEdited: DateTime.now(),
        publishedDate: _editableStory.publishedDate ?? DateTime.now(),
        status: StoryStatus.published);
    Story? updatedStoryMeta = await _storyService.updateStory(_editableStory);

    if (updatedStoryMeta == null) {
      if (kDebugMode) print("EditStoryVM: Failed to update story metadata for publish.");
      _isSaving = false; notifyListeners(); return false;
    }
    _editableStory = updatedStoryMeta;

    // Update Chapter (mark as complete)
    Chapter? updatedChapter = await _storyService.updateChapter(
        chapterId: _editableChapter.id,
        storyId: _editableStory.id,
        title: chapterTitleController.text,
        content: contentController.text,
        chapterNumber: _chapterIndex + 1,
        isComplete: true);

    _isSaving = false;
    if (updatedChapter != null) {
      _editableChapter = updatedChapter;
      if (_chapterIndex >= 0 && _chapterIndex < _editableStory.chapters.length) {
        _editableStory.chapters[_chapterIndex] = _editableChapter;
      } else if (_editableStory.chapters.isEmpty && _chapterIndex == 0) {
        _editableStory.chapters.add(_editableChapter);
      }
      _originalStory = _editableStory.copyWith(
          chapters: List.from(_editableStory.chapters.map((c) => c.copyWith()))
      );
      _hasUnsavedChanges = false;
      _justSaved = true;
      if (kDebugMode) print('EditStoryVM: Chapter published successfully (ID: ${updatedChapter.id}).');
    } else {
      if (kDebugMode) print('EditStoryVM: Failed to publish chapter to backend.');
    }
    notifyListeners();
    return updatedChapter != null;
  }

  void toggleBold() {
    notifyListeners();
  }

  void toggleItalic() {
    notifyListeners();
  }

  void toggleUnderline() {
    notifyListeners();
  }

  void toggleBulletList() {
    notifyListeners();
  }

  void startDictation() {
    notifyListeners();
  }

  @override
  void dispose() {
    chapterTitleController.removeListener(_onTextChanged);
    contentController.removeListener(_onTextChanged);
    chapterTitleController.dispose();
    contentController.dispose();
    if (kDebugMode) print("EditStoryViewModel Disposed");
    super.dispose();
  }
}
