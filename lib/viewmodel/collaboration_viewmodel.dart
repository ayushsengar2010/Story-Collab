// viewmodel/collaboration_viewmodel.dart
import 'package:flutter/foundation.dart'; // For ChangeNotifier and kDebugMode
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/data/models/author_model.dart'; // Import Author model
import 'package:collabwrite/services/story_service.dart'; // Import StoryService
// Import UserService if you need to fetch full owner details (Optional)
// import 'package:collabwrite/services/user_service.dart';

enum CollaborationTab { collaborators, versionHistory }

class CollaborationViewModel extends ChangeNotifier {
  final StoryService _storyService = StoryService();
  // final UserService _userService = UserService(); // Optional: For fetching full owner details
  Story _story; // The story being managed
  CollaborationTab _selectedTab = CollaborationTab.collaborators;

  // --- State for API Collaborators ---
  List<Author> _apiCollaborators = [];
  bool _isLoadingCollaborators = false;
  String? _collaboratorError;

  // --- Getters ---
  String get storyTitle => _story.title;
  int get storyId => _story.id;
  int get chapterCount => _story.chapters?.length ?? 0;
  // Getter for the collaborators fetched from API (guaranteed to include owner if fetch succeeds/fails gracefully)
  List<Author> get collaborators => List.unmodifiable(_apiCollaborators);
  bool get isLoadingCollaborators => _isLoadingCollaborators;
  String? get collaboratorError => _collaboratorError;

  // --- Other Getters ---
  List<PendingReviewRequest> get pendingReviewRequests =>
      List.unmodifiable(_story.pendingReviewRequests);
  bool get isShareableLinkActive => _story.isShareableLinkActive;
  bool get isReviewSystemActive => _story.isReviewSystemActive;
  CollaborationTab get selectedTab => _selectedTab;
  Story get storyObjectForViewModel => _story;

  // --- Constructor ---
  CollaborationViewModel({required Story story}) : _story = story {
    // Load collaborators when the ViewModel is created
    loadCollaborators();
  }

  // --- UI Actions ---
  void selectTab(CollaborationTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  // --- Collaborator API Methods ---

  Future<void> loadCollaborators({bool showLoading = true}) async {
    if (showLoading) {
      _isLoadingCollaborators = true;
      _collaboratorError = null;
      notifyListeners();
    }

    try {
      // Fetch collaborators - this might return an empty list now if body was null
      List<Author> fetchedCollaborators =
          await _storyService.getCollaboratorsByStory(_story.id);
      _apiCollaborators = fetchedCollaborators; // Assign fetched list
      _collaboratorError =
          null; // Clear error on successful fetch (even if list is empty)

      // --- Ensure Owner is Present ---
      final String ownerIdString = _story.authorId;
      final bool ownerAlreadyInList = _apiCollaborators
          .any((collab) => collab.id.toString() == ownerIdString);

      if (!ownerAlreadyInList) {
        // Owner details from the _story object
        final Author storyOwner = Author(
          // Safely parse owner ID string to int
          id: int.tryParse(ownerIdString) ??
              0, // Use 0 or handle error if parse fails
          name: _story.authorName,
          // Provide placeholder/default values for fields missing in Story model
          email: '', // Placeholder - Need owner's email if not in Story model
          bio: '', // Placeholder
          followers: 0, // Placeholder
          following: 0, // Placeholder
          storiesCount: 0, // Placeholder
          isVerified: false, // Placeholder
          // profileImage: _story.authorProfileImage, // Add if available in Story model
        );

        if (kDebugMode) {
          print(
              "CollaborationVM: Owner (ID: $ownerIdString, Name: ${_story.authorName}) not found in API response. Adding manually.");
        }
        // Add the owner to the beginning of the list
        _apiCollaborators.insert(0, storyOwner);

        // Optional: Sort the list after adding owner (e.g., owner first, then alphabetical)
        // _apiCollaborators.sort((a, b) {
        //   if (a.id.toString() == ownerIdString) return -1;
        //   if (b.id.toString() == ownerIdString) return 1;
        //   return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        // });
      }
      // --- END: Ensure Owner is Present ---

      if (kDebugMode)
        print(
            "CollaborationVM: Final collaborators list size: ${_apiCollaborators.length}");
    } catch (e) {
      if (kDebugMode) print("CollaborationVM: Error loading collaborators: $e");
      _collaboratorError = "Failed to load collaborators. Please try again.";
      _apiCollaborators = []; // Clear list on error

      // --- START: Add Owner even on error? ---
      // Even if fetching others failed, add the owner so the list isn't completely empty
      final String ownerIdString = _story.authorId;
      final Author storyOwner = Author(
          id: int.tryParse(ownerIdString) ?? 0,
          name: _story.authorName,
          email: '',
          bio: '',
          followers: 0,
          following: 0,
          storiesCount: 0,
          isVerified: false);
      _apiCollaborators = [storyOwner]; // Show only owner if fetch fails
      // Keep the error message to indicate others failed to load
      if (kDebugMode)
        print("CollaborationVM: Fetch failed, displaying only owner.");
      // --- END: Add Owner even on error? ---
    } finally {
      _isLoadingCollaborators = false;
      notifyListeners(); // Notify UI about loading completion, data change, or error
    }
  }

  /// Invites a collaborator by email. Returns true on success, false otherwise.
  /// Sets collaboratorError on failure.
  Future<bool> inviteCollaborator(String email) async {
    if (kDebugMode) {
      print(
          'CollaborationVM: Inviting $email to collaborate on story ID ${_story.id}');
    }
    _collaboratorError = null; // Clear previous errors
    // Optionally: Set an _isInviting state = true and notifyListeners()

    bool success = false;
    try {
      success = await _storyService.addCollaborator(_story.id, email);
    } catch (e) {
      if (kDebugMode)
        print("CollaborationVM: Error during addCollaborator call: $e");
      _collaboratorError =
          "An error occurred: ${e.toString()}"; // Show specific error
      success = false;
    }

    // Optionally: Set _isInviting = false and notifyListeners()

    if (success) {
      if (kDebugMode)
        print("CollaborationVM: Invitation successful for $email.");
      await loadCollaborators(showLoading: false); // Refresh list, will notify
      return true;
    } else {
      if (kDebugMode) print("CollaborationVM: Invitation failed for $email.");
      // If service didn't throw but returned false, set a generic error
      if (_collaboratorError == null) {
        _collaboratorError =
            "Failed to invite '$email'. User not found or already a collaborator?";
      }
      notifyListeners(); // Notify about the error
      return false;
    }
  }

  /// Removes a collaborator by their user ID. Returns true on success, false otherwise.
  /// Sets collaboratorError on failure.
  Future<bool> removeCollaborator(int userIdToRemove) async {
    _collaboratorError = null; // Clear previous errors
    // Prevent removing the story owner
    if (userIdToRemove.toString() == _story.authorId) {
      if (kDebugMode) print("CollaborationVM: Cannot remove the story owner.");
      _collaboratorError = "Cannot remove the story owner.";
      notifyListeners();
      return false;
    }

    if (kDebugMode) {
      print(
          'CollaborationVM: Removing collaborator ID $userIdToRemove from story ID ${_story.id}');
    }
    // Optionally: Set _isRemoving = true and notifyListeners()

    bool success = false;
    try {
      success =
          await _storyService.removeCollaborator(_story.id, userIdToRemove);
    } catch (e) {
      if (kDebugMode)
        print("CollaborationVM: Error during removeCollaborator call: $e");
      _collaboratorError = "An error occurred: ${e.toString()}";
      success = false;
    }

    // Optionally: Set _isRemoving = false;

    if (success) {
      if (kDebugMode)
        print(
            "CollaborationVM: Successfully removed collaborator ID $userIdToRemove.");
      await loadCollaborators(showLoading: false); // Refresh list, will notify
      return true;
    } else {
      if (kDebugMode)
        print(
            "CollaborationVM: Failed to remove collaborator ID $userIdToRemove.");
      // If service didn't throw but returned false, set a generic error
      if (_collaboratorError == null) {
        _collaboratorError = "Failed to remove collaborator.";
      }
      notifyListeners(); // Notify about the error
      return false;
    }
  }

  // --- Existing Data Modification Methods (Simulated/Local State) ---
  // These methods manage local state of the _story object and should
  // ideally be backed by corresponding API calls in StoryService if needed.

  Future<void> toggleShareableLink(bool isActive) async {
    if (kDebugMode)
      print('Setting shareable link for "${_story.title}" to $isActive');
    // Update local state first for responsiveness
    _story = _story.copyWith(isShareableLinkActive: isActive);
    notifyListeners();
    // TODO: Implement API call to persist this change using StoryService.
    // try {
    //   bool success = await _storyService.updateStorySettings(_story.id, isShareable: isActive);
    //   if (!success) { // Revert on failure
    //      _story = _story.copyWith(isShareableLinkActive: !isActive);
    //      notifyListeners();
    //      // Show error message
    //   }
    // } catch (e) { /* Handle error, revert state */ }
  }

  Future<void> toggleReviewSystem(bool isActive) async {
    if (kDebugMode)
      print('Setting review system for "${_story.title}" to $isActive');
    _story = _story.copyWith(isReviewSystemActive: isActive);
    notifyListeners();
    // TODO: Implement API call to persist this change using StoryService.
  }

  Future<void> reviewPendingRequest(String requestId,
      {required bool approve}) async {
    if (kDebugMode)
      print(
          '${approve ? "Approving" : "Rejecting"} request $requestId for "${_story.title}"');
    // Update local state: Remove the request optimistically
    final originalRequests =
        List<PendingReviewRequest>.from(_story.pendingReviewRequests);
    final updatedRequests = _story.pendingReviewRequests
        .where((req) => req.requestId != requestId)
        .toList();
    _story = _story.copyWith(pendingReviewRequests: updatedRequests);
    notifyListeners();

    // TODO: Implement API call using StoryService.
    // try {
    //    bool success = await _storyService.processReviewRequest(requestId, approve: approve);
    //    if (!success) { // Revert on failure
    //       _story = _story.copyWith(pendingReviewRequests: originalRequests);
    //       notifyListeners();
    //      // Show error message
    //    }
    // } catch (e) { /* Handle error, revert state */ }
  }

  /// Refreshes the ViewModel's internal story object.
  void refreshStory(Story updatedStory) {
    if (_story.id == updatedStory.id) {
      _story = updatedStory;
      // Consider if collaborators need refreshing based on this update
      // loadCollaborators(showLoading: false);
      notifyListeners();
    }
  }
} // End of CollaborationViewModel
