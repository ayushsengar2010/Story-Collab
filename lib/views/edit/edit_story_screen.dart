// views/edit_story/edit_story_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collabwrite/core/constants/colors.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/viewmodel/edit_story_viewmodel.dart';
import 'package:collabwrite/views/widgets/custom_bottom_nav_bar.dart';
// Import other screens for bottom nav
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:collabwrite/views/create/create_screen.dart';
import 'package:collabwrite/views/library/library_screen.dart';
import 'package:collabwrite/views/profile/profile_screen.dart';

import '../collab/collaboration_screen.dart';

class EditStoryScreen extends StatefulWidget {
  final Story story;
  final Chapter chapter;

  const EditStoryScreen(
      {super.key, required this.story, required this.chapter});

  @override
  State<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends State<EditStoryScreen> {
  final int _initialSelectedNavIndex = 2; // Default, can be dynamic

  // Helper methods now take viewModel as a parameter

  void _onNavItemTapped(
      BuildContext context, int index, EditStoryViewModel viewModel) {
    if (index == _initialSelectedNavIndex) return;

    if (viewModel.hasUnsavedChanges) {
      _showUnsavedChangesDialog(context, viewModel,
          () => _navigateToScreen(context, index, viewModel));
    } else {
      _navigateToScreen(context, index, viewModel);
    }
  }

  void _navigateToScreen(
      BuildContext context, int index, EditStoryViewModel viewModel) {
    // Pass the current story state if navigating away, so other screens might be aware of it
    // though provider state management is preferred for cross-screen updates.
    final currentStory = viewModel.storyObjectForCollaboration;

    final screens = [
      const HomeScreen(),
      const CreateScreen(), // Potentially pass currentStory if CreateScreen can take it
      const LibraryScreen(),
      const ProfileScreen(),
    ];
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation1, animation2) => screens[index],
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  Future<bool> _onWillPop(
      BuildContext context, EditStoryViewModel viewModel) async {
    if (viewModel.hasUnsavedChanges) {
      await _showUnsavedChangesDialog(
          context,
          viewModel,
          () => Navigator.of(context)
              .pop(viewModel.currentStoryState) // Pop with current story state
          );
      return false; // We might handle pop in dialog or onActionAfterSaveOrDiscard
    }
    Navigator.of(context)
        .pop(viewModel.currentStoryState); // Pop with current story state
    return false; // We handled the pop manually
  }

  Future<void> _showUnsavedChangesDialog(
      BuildContext context,
      EditStoryViewModel viewModel,
      VoidCallback onActionAfterSaveOrDiscard) async {
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture ScaffoldMessenger

    final action = await showDialog<String>(
      // Return a string to indicate action
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Do you want to save them as a draft before leaving?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, 'discard'); // Discard
            },
            child:
                const Text('Discard', style: TextStyle(color: AppColors.tint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext, 'save'); // Save then proceed
            },
            child: const Text('Save Draft & Leave',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (action == 'save') {
      bool saved = await viewModel.saveDraft();
      // Use the captured ScaffoldMessenger to show SnackBar
      _showSnackBarWithSpecificMessenger(scaffoldMessenger,
          saved ? 'Draft saved successfully!' : 'Could not save draft.',
          isError: !saved);
      onActionAfterSaveOrDiscard();
    } else if (action == 'discard') {
      onActionAfterSaveOrDiscard();
    }
  }

  // Use this if you need to show snackbar from a context that might not be the main scaffold's
  void _showSnackBarWithSpecificMessenger(
      ScaffoldMessengerState messenger, String message,
      {bool isError = false}) {
    messenger.showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.tint : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        duration: const Duration(seconds: 2)));
  }

  void _showSnackBar(BuildContext scaffoldContext, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.tint : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        duration: const Duration(seconds: 2)));
  }

  Widget _toolbarButton(
      { // Removed context parameter, as it's not used directly by this simple helper
      IconData? icon,
      Widget? child,
      required String tooltip,
      required VoidCallback onPressed}) {
    return IconButton(
      icon: child ?? Icon(icon, size: 22, color: Colors.grey[700]),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provide EditStoryViewModel scoped to this screen instance
    return ChangeNotifierProvider(
      create: (_) =>
          EditStoryViewModel(story: widget.story, chapter: widget.chapter),
      child: Consumer<EditStoryViewModel>(
        // Use Consumer to get the ViewModel
        builder: (context, viewModel, child) {
          // viewModel is the instance from ChangeNotifierProvider
          return WillPopScope(
            onWillPop: () => _onWillPop(
                context, viewModel), // Pass current context and viewModel
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 1.0,
                shadowColor: Colors.grey[200],
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.background),
                    onPressed: () async {
                      // Use the viewModel from the Consumer's builder
                      if (await _onWillPop(context, viewModel)) {
                        // This part of _onWillPop now handles Navigator.pop itself
                      }
                    }),
                title: Text(
                  viewModel.appBarTitle,
                  style: const TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (viewModel.justSaved && !viewModel.isSaving)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: const Text('Saved',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.green.shade400,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        labelPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (viewModel.isSaving)
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.0, color: AppColors.primary)),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Column(
                children: [
                  // Story Info Banner
                  Container(
                    color: AppColors.primary.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            viewModel.storyTitle,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary), // Adjusted color
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Chip(
                          label: Text(viewModel.chapterProgress,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          labelPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  // Chapter Title
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHAPTER TITLE',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: viewModel.chapterTitleController,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Enter chapter title',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Editor Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!))),
                    child: Row(
                      children: [
                        _toolbarButton(
                          // No context needed here
                          child: const CircleAvatar(
                            backgroundColor: AppColors.tint,
                            radius: 12,
                            child: Text('B',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          tooltip: 'Bold',
                          onPressed: viewModel.toggleBold,
                        ),
                        _toolbarButton(
                            icon: Icons.format_italic,
                            tooltip: 'Italic',
                            onPressed: viewModel.toggleItalic),
                        _toolbarButton(
                            icon: Icons.format_underline,
                            tooltip: 'Underline',
                            onPressed: viewModel.toggleUnderline),
                        _toolbarButton(
                            icon: Icons.format_list_bulleted,
                            tooltip: 'Bullet List',
                            onPressed: viewModel.toggleBulletList),
                        const Spacer(),
                        Text('${viewModel.wordCount} words',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(width: 8),
                        _toolbarButton(
                            icon: Icons.mic_none,
                            tooltip: 'Dictate',
                            onPressed: viewModel.startDictation),
                      ],
                    ),
                  ),
                  // Text Editor Area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: TextField(
                        controller: viewModel.contentController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        cursorColor: AppColors.primary,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        decoration: InputDecoration(
                          hintText:
                              'Tap to start writing or dictating your story....',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ),
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    _showSnackBar(context,
                                        'Preview not yet implemented.'); // Use context from Consumer
                                  },
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textGrey,
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  child: const Text('Preview'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    // viewModel is available from the Consumer's builder
                                    Navigator.pushNamed(
                                      context, // Use context from Consumer
                                      CollaborationScreen.routeName,
                                      arguments:
                                          viewModel.storyObjectForCollaboration,
                                    ).then((returnedValue) {
                                      if (returnedValue is Story) {
                                        viewModel
                                            .refreshStoryAfterCollaboration(
                                                returnedValue);
                                        _showSnackBar(context,
                                            "Collaboration data synced."); // Use context from Consumer
                                      } else if (returnedValue != null) {
                                        print(
                                            "Returned unexpected value from CollaborationScreen: $returnedValue");
                                      }
                                    });
                                  },
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.tint,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  child: const Text('Collaboration'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: viewModel.isSaving
                                      ? null
                                      : () async {
                                          bool success =
                                              await viewModel.saveDraft();
                                          _showSnackBar(
                                              context, // Use context from Consumer
                                              success
                                                  ? 'Draft saved!'
                                                  : 'Failed to save draft.',
                                              isError: !success);
                                        },
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textGrey,
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  child: Text(viewModel.isSaving
                                      ? 'Saving...'
                                      : 'Save Draft'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: viewModel.isSaving
                                      ? null
                                      : () async {
                                    bool success =
                                    // CORRECTED HERE:
                                    await viewModel.publishChanges();
                                    _showSnackBar(
                                        context,
                                        success
                                            ? 'Changes published!'
                                            : 'Failed to publish.',
                                        isError: !success);
                                    if (success) {
                                      // Optionally pop or indicate success more permanently
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(
                                          color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8))),
                                  child: Text(viewModel.isSaving ? 'Publishing...' : 'Publish Changes'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: CustomBottomNavBar(
                selectedIndex: _initialSelectedNavIndex,
                onItemTapped: (index) => _onNavItemTapped(
                    context, index, viewModel), // Pass viewModel from Consumer
              ),
            ),
          );
        },
      ),
    );
  }
}
