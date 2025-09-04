// views/create/create_screen.dart
import 'dart:io';
import 'package:collabwrite/core/constants/colors.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/viewmodel/create_viewmodel.dart';
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:collabwrite/views/library/library_screen.dart';
import 'package:collabwrite/views/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class CreateScreen extends StatefulWidget {
  final Story? draftStory;

  const CreateScreen({super.key, this.draftStory});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final int _selectedNavIndex = 1;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _writingController;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  bool _isControllersInitialized = false; // Flag to prevent controller overwrite

  @override
  void initState() {
    super.initState();
    // Initialize controllers without accessing provider
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _writingController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("CreateScreen: didChangeDependencies called");
    final viewModel = Provider.of<CreateViewModel>(context, listen: false);

    // Initialize viewModel and controllers only once
    if (!_isControllersInitialized) {
      viewModel.initialize(draftStory: widget.draftStory);
      _titleController.text = viewModel.title;
      _descriptionController.text = viewModel.description;
      _writingController.text = viewModel.writingContent;

      // Debug prints to verify controller values
      print("CreateScreen: Set titleController.text = ${viewModel.title}");
      print(
          "CreateScreen: Set descriptionController.text = ${viewModel.description}");
      print(
          "CreateScreen: Set writingController.text = ${viewModel.writingContent}");

      _isControllersInitialized = true;
    }

    // Add listeners to update viewModel (only add once)
    if (_titleController.hasListeners == false) {
      _titleController.addListener(() {
        Future.delayed(Duration.zero, () {
          if (_titleController.text != viewModel.title) {
            viewModel.setTitle(_titleController.text);
            print("CreateScreen: Updated viewModel.title = ${_titleController.text}");
          }
        });
      });
    }
    if (_descriptionController.hasListeners == false) {
      _descriptionController.addListener(() {
        Future.delayed(Duration.zero, () {
          if (_descriptionController.text != viewModel.description) {
            viewModel.setDescription(_descriptionController.text);
            print("CreateScreen: Updated viewModel.description = ${_descriptionController.text}");
          }
        });
      });
    }
    if (_writingController.hasListeners == false) {
      _writingController.addListener(() {
        Future.delayed(Duration.zero, () {
          if (_writingController.text != viewModel.writingContent) {
            viewModel.setWritingContent(_writingController.text);
            print("CreateScreen: Updated viewModel.writingContent = ${_writingController.text}");
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _writingController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedNavIndex) return;

    final viewModel = context.read<CreateViewModel>();
    if (viewModel.hasUnsavedChanges) {
      _showUnsavedChangesDialog(() => _navigateToScreen(index));
    } else {
      _navigateToScreen(index);
    }
  }

  void _navigateToScreen(int index) {
    final routes = [
      '/home',
      '/create',
      '/library',
      '/profile',
    ];
    if (index != _selectedNavIndex) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  Future<bool> _onWillPop() async {
    final viewModel = context.read<CreateViewModel>();
    if (viewModel.hasUnsavedChanges) {
      _showUnsavedChangesDialog(() => Navigator.of(context).pop());
      return false;
    }
    return true;
  }

  Future<void> _showUnsavedChangesDialog(VoidCallback onDiscard) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Unsaved Changes'),
        content: const Text(
            'Do you want to save your changes as a draft before leaving?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDiscard();
            },
            child: const Text('Discard', style: TextStyle(color: AppColors.tint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool saved = await _saveDraft();
              if (mounted) {
                if (saved) {
                  _showSnackBar('Draft saved successfully!');
                } else {
                  _showSnackBar(
                      'Could not save draft (e.g., title missing or login required).',
                      isError: true);
                }
              }
              onDiscard();
            },
            child: const Text('Save Draft',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<bool> _saveDraft() async {
    final viewModel = context.read<CreateViewModel>();
    try {
      bool success = await viewModel.saveDraft();
      if (!success && mounted) {
        final userId = await viewModel.getCurrentUserId();
        if (userId == null) {
          _showSnackBar('Please log in to save your draft.', isError: true);
          Navigator.pushNamed(context, '/login');
        } else {
          _showSnackBar('Failed to save draft. Please enter a title.',
              isError: true);
        }
      } else if (success && mounted) {
        _showSnackBar('Draft saved successfully!');
      }
      return success;
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving draft: $e', isError: true);
      }
      return false;
    }
  }

  Future<void> _publishStory() async {
    final viewModel = context.read<CreateViewModel>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Publish Story?'),
        content: const Text(
            'This will make your story publicly visible. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      bool success = await viewModel.publishStory();
      if (success && mounted) {
        _showSnackBar('Story published successfully!');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LibraryScreen()));
      } else if (!success && mounted) {
        final userId = await viewModel.getCurrentUserId();
        if (userId == null) {
          _showSnackBar('Please log in to publish your story.', isError: true);
          Navigator.pushNamed(context, '/login');
        } else {
          _showSnackBar(
              'Failed to publish story. Ensure title, content, and genres are provided.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error publishing story: $e', isError: true);
      }
    }
  }

  void _previewStory() {
    final viewModel = context.read<CreateViewModel>();
    if (viewModel.title.trim().isEmpty) {
      _showSnackBar('Add a title to preview.');
      return;
    }
    if (viewModel.writingContent.trim().isEmpty) {
      _showSnackBar('Add some content to preview.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.only(top: 10),
              child: Column(children: [
                Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Preview",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context)),
                        ])),
                const Divider(),
                Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        if (viewModel.coverImagePath != null)
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.file(File(viewModel.coverImagePath!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover)),
                        const SizedBox(height: 15),
                        Text(viewModel.title,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.background)),
                        const SizedBox(height: 10),
                        if (viewModel.description.isNotEmpty)
                          Text(viewModel.description,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700],
                                  height: 1.4)),
                        const SizedBox(height: 5),
                        if (viewModel.selectedGenres.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: viewModel.selectedGenres
                                      .map((genre) => Chip(
                                      label: Text(genre),
                                      backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                      labelStyle: const TextStyle(
                                          color: AppColors.primary),
                                      side: BorderSide.none,
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2)))
                                      .toList())),
                        const SizedBox(height: 20),
                        SelectableText(viewModel.writingContent,
                            style: const TextStyle(
                                fontSize: 16, height: 1.6, color: Colors.black87)),
                      ],
                    )),
              ]),
            );
          }),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger =
        _scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.tint : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        duration: const Duration(seconds: 3)));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.background)));
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    print("CreateScreen: Building TextField with text: ${controller.text}");
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: AppColors.primary,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87, // Explicitly set text color
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white, // Use solid white for better contrast
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStoryTypeSelector(BuildContext context) {
    final viewModel = context.watch<CreateViewModel>();
    return SegmentedButton<String>(
      segments: viewModel.availableStoryTypes.map((type) {
        IconData icon;
        switch (type) {
          case 'Single Story':
            icon = Icons.article_outlined;
            break;
          case 'Chapter-based':
            icon = Icons.list_alt_outlined;
            break;
          case 'Collaborative':
            icon = Icons.people_alt_outlined;
            break;
          default:
            icon = Icons.create;
        }
        return ButtonSegment<String>(
            value: type, label: Text(type), icon: Icon(icon));
      }).toList(),
      selected: {viewModel.selectedStoryType},
      onSelectionChanged: (Set<String> newSelection) {
        context.read<CreateViewModel>().selectStoryType(newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.containerBackground.withOpacity(0.5),
        foregroundColor: AppColors.textGrey,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: AppColors.primary,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      showSelectedIcon: false,
    );
  }

  Widget _buildCoverImageSelector(BuildContext context) {
    final viewModel = context.watch<CreateViewModel>();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () => context.read<CreateViewModel>().pickCoverImage(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.containerBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            image: viewModel.coverImagePath != null
                ? DecorationImage(
              image: FileImage(File(viewModel.coverImagePath!)),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: viewModel.coverImagePath == null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 40, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'Tap to add Cover Image',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(Recommended: 16:9 ratio)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          )
              : Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Colors.white, size: 18),
                    onPressed: () =>
                        context.read<CreateViewModel>().pickCoverImage(),
                    tooltip: 'Change Cover Image',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 18),
                    onPressed: () =>
                        context.read<CreateViewModel>().removeCoverImage(),
                    tooltip: 'Remove Cover Image',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreSelector(BuildContext context) {
    final viewModel = context.watch<CreateViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewModel.selectedGenres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: viewModel.selectedGenres.map((genre) {
                return Chip(
                  label: Text(genre),
                  labelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  onDeleted: () =>
                      context.read<CreateViewModel>().toggleGenre(genre),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  deleteIconColor: AppColors.primary.withOpacity(0.7),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
        Text(
          viewModel.selectedGenres.isEmpty
              ? 'Select Genres (Required)'
              : 'Add More Genres',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: viewModel.popularGenres
              .where((genre) => !viewModel.selectedGenres.contains(genre))
              .map((genre) {
            return ActionChip(
              label: Text(genre),
              labelStyle: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: AppColors.containerBackground.withOpacity(0.5),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onPressed: () =>
                  context.read<CreateViewModel>().toggleGenre(genre),
              avatar: const Icon(Icons.add, size: 16, color: AppColors.textGrey),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWritingSection(BuildContext context) {
    final writingContent =
    context.select((CreateViewModel vm) => vm.writingContent);
    int wordCount = writingContent
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.containerBackground.withOpacity(0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              _toolbarButton(Icons.format_bold, 'Bold', () {}),
              _toolbarButton(Icons.format_italic, 'Italic', () {}),
              _toolbarButton(Icons.format_underline, 'Underline', () {}),
              const Spacer(),
              Text(
                '$wordCount words',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: TextField(
            controller: _writingController,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            cursorColor: AppColors.primary,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87, // Explicitly set text color
            ),
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Start writing your story here...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.textGrey,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateViewModel>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldMessengerKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1.0,
          shadowColor: Colors.grey[200],
          title: const Text(
            'Create New Story',
            style: TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.background),
            onPressed: () => _onWillPop().then((allowPop) {
              if (allowPop) Navigator.of(context).pop();
            }),
          ),
          actions: [
            TextButton.icon(
              icon: viewModel.isSaving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(viewModel.isSaving ? 'Saving...' : 'Save Draft'),
              onPressed: viewModel.isSaving ? null : _saveDraft,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.visibility_outlined,
                color: AppColors.textGrey,
              ),
              tooltip: 'Preview Story',
              onPressed: viewModel.isSaving ? null : _previewStory,
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('1. Story Type'),
                _buildStoryTypeSelector(context),
                _buildSectionHeader('2. Story Details'),
                _buildStyledTextField(
                  controller: _titleController,
                  hint: 'Enter your story title',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 15),
                _buildCoverImageSelector(context),
                const SizedBox(height: 15),
                _buildStyledTextField(
                  controller: _descriptionController,
                  hint: 'Write a short description or synopsis',
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 15),
                _buildGenreSelector(context),
                _buildSectionHeader('3. Content'),
                _buildWritingSection(context),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.publish_outlined),
                    label: const Text('Publish Story'),
                    onPressed: viewModel.isSaving ? null : _publishStory,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedNavIndex,
          onItemTapped: _onNavItemTapped,
        ),
      ),
    );
  }
}