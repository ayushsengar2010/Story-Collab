import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:collabwrite/core/constants/assets.dart';
import 'package:collabwrite/core/constants/colors.dart';
import 'package:collabwrite/viewmodel/library_viewmodel.dart';
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:collabwrite/views/create/create_screen.dart';
import 'package:collabwrite/views/profile/profile_screen.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/views/widgets/custom_bottom_nav_bar.dart';
import 'package:collabwrite/views/widgets/empty_state.dart';
import 'package:collabwrite/services/story_service.dart';
import 'package:collabwrite/viewmodel/profile_viewmodel.dart'; // Import ProfileViewModel

import '../../core/utils/date_formatter.dart';
import '../edit/edit_story_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final int _selectedNavIndex = 2;
  final TextEditingController _searchController = TextEditingController();
  late final LibraryViewModel _viewModel;
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<LibraryViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel.loadStories();
      }
    });

    _searchController.text = _viewModel.searchQuery;
    _searchController.addListener(() {
      _viewModel.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedNavIndex) return;
    final screens = [
      const HomeScreen(),
      const CreateScreen(),
      const LibraryScreen(),
      const ProfileScreen(),
    ];
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => screens[index],
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _navigateToCreateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateScreen()),
    ).then((_) {
      print(
          "Returned from CreateScreen (new story), reloading stories in Library.");
      _viewModel.loadStories(forceRefresh: true);
    });
  }

  Future<void> _navigateToStoryDetail(Story storyFromList) async {
    _showLoadingDialog();

    Story? storyMetadata = await _storyService.getStoryById(storyFromList.id);
    if (!mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    if (storyMetadata == null) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar(
          'Could not load story details for "${storyFromList.title}".',
          isError: true);
      return;
    }

    List<Chapter> chapters =
        await _storyService.getChaptersByStory(storyMetadata.id);
    if (!mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    storyMetadata = storyMetadata.copyWith(chapters: chapters);

    if (storyMetadata.chapters.isNotEmpty) {
      Chapter chapterToEdit = storyMetadata.chapters.first;

      print(
          "Navigating to EditStoryScreen with story: ${storyMetadata.title}, Chapter to edit: ${chapterToEdit.title}");
      print(
          "Chapter content being passed: '${chapterToEdit.content}' (empty: ${chapterToEdit.content.isEmpty})");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditStoryScreen(
            story: storyMetadata!,
            chapter: chapterToEdit,
          ),
        ),
      ).then((returnedValue) {
        if (returnedValue != null) {
          print("Returned from EditStoryScreen, reloading stories in Library.");
          _viewModel.loadStories(forceRefresh: true);
        }
      });
    } else {
      if (kDebugMode)
        print(
            "Story '${storyMetadata.title}' (ID: ${storyMetadata.id}) has no chapters from backend.");
      _showSnackBar(
          'No content chapters found for "${storyMetadata.title}". Opening editor to add content.',
          isError: false);

      Chapter placeholderChapter = Chapter(
          id: 'new_ch_for_${storyMetadata.id}',
          title: storyMetadata.storyType.toLowerCase() == 'single story'
              ? storyMetadata.title
              : 'New Chapter 1',
          content: '',
          isComplete: false);

      storyMetadata = storyMetadata.copyWith(chapters: [placeholderChapter]);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditStoryScreen(
            story: storyMetadata!,
            chapter: placeholderChapter,
          ),
        ),
      ).then((returnedValue) {
        if (returnedValue != null) {
          print(
              "Returned from EditStoryScreen (after no chapters found), reloading stories in Library.");
          _viewModel.loadStories(forceRefresh: true);
        }
      });
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Loading story..."),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1.0,
      shadowColor: Colors.grey[200],
      title: viewModel.isSearchActive
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                  hintText: 'Search library...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[600])),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            )
          : const Text('My Library',
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          icon: Icon(viewModel.isSearchActive ? Icons.close : Icons.search,
              color: Colors.grey[700]),
          tooltip: viewModel.isSearchActive ? 'Close Search' : 'Search Library',
          onPressed: () => context.read<LibraryViewModel>().toggleSearch(),
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: Colors.grey[700]),
          tooltip: 'Filter & Sort',
          onPressed: () => _showFilterBottomSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
          tooltip: 'Create New Story',
          onPressed: _navigateToCreateScreen,
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget _buildStoryItem(BuildContext context, Story story) {
    int totalChapters = story.chapters?.length ?? 0;
    int completedChapters =
        story.chapters?.where((c) => c.isComplete).length ?? 0;
    double progress =
        totalChapters > 0 ? completedChapters / totalChapters : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.grey[100],
      child: InkWell(
        onTap: () => _navigateToStoryDetail(story),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildCoverImageThumbnail(story.coverImage),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _buildStatusChip(story.status),
                    const SizedBox(width: 8),
                    Text(story.storyType,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                  ]),
                  const SizedBox(height: 8),
                  if (story.storyType.toLowerCase() == 'chapter-based' ||
                      story.storyType.toLowerCase() == 'chapter_based')
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3)),
                          const SizedBox(height: 4),
                          Text(
                              '$completedChapters / $totalChapters Chapters Complete',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[700])),
                          const SizedBox(height: 6),
                        ]),
                  Text(
                      'Edited: ${DateFormatter.formatRelativeTime(story.lastEdited)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (story.status == StoryStatus.published &&
                      story.publishedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                          'Published: ${DateFormatter.formatRelativeTime(story.publishedDate)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                ])),
            SizedBox(
                width: 30,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  color: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  tooltip: 'Story Options',
                  onPressed: () => _showStoryOptions(context, story),
                  constraints: const BoxConstraints(),
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildCoverImageThumbnail(String? coverImagePath) {
    ImageProvider? imageProvider;
    if (coverImagePath != null && coverImagePath.isNotEmpty) {
      if (coverImagePath.startsWith('http')) {
        imageProvider = NetworkImage(coverImagePath);
      } else if (coverImagePath.startsWith('assets/')) {
        imageProvider = AssetImage(coverImagePath);
      } else {
        print(
            "Cover image path is not a URL or asset: $coverImagePath. Displaying placeholder.");
      }
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
            width: 70,
            height: 90,
            color: Colors.grey[200],
            child: imageProvider != null
                ? Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print(
                          "Error loading cover image: $coverImagePath, $error");
                      return const Icon(Icons.image_not_supported,
                          color: Colors.grey);
                    },
                  )
                : const Center(
                    child:
                        Icon(Icons.menu_book, color: Colors.grey, size: 30))));
  }

  Widget _buildStatusChip(StoryStatus status) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3), width: 0.5)),
        child: Text(_getStatusText(status),
            style: TextStyle(
                fontSize: 11,
                color: _getStatusColor(status),
                fontWeight: FontWeight.w500)));
  }

  void _showFilterBottomSheet(BuildContext context) {
    final viewModel = context.read<LibraryViewModel>();
    Set<StoryStatus> tempSelectedStatuses =
        Set.from(viewModel.selectedStatuses);
    Set<String> tempSelectedTypes = Set.from(viewModel.selectedTypes);
    StorySortOption tempSortOption = viewModel.sortOption;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (statefulContext, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(statefulContext).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Filter & Sort',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () => setModalState(() {
                          tempSelectedStatuses.clear();
                          tempSelectedTypes.clear();
                          tempSortOption = StorySortOption.lastEditedDesc;
                        }),
                    child: const Text('Reset All')),
              ]),
              const Divider(height: 20),
              const Text('Status',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: StoryStatus.values.map((status) {
                    final bool isSelected =
                        tempSelectedStatuses.contains(status);
                    return FilterChip(
                        label: Text(_getStatusText(status)),
                        selected: isSelected,
                        onSelected: (selected) => setModalState(() => selected
                            ? tempSelectedStatuses.add(status)
                            : tempSelectedStatuses.remove(status)),
                        selectedColor: _getStatusColor(status).withOpacity(0.2),
                        checkmarkColor: _getStatusColor(status),
                        labelStyle: TextStyle(
                            color: isSelected
                                ? _getStatusColor(status)
                                : Colors.grey[700]),
                        side: BorderSide(
                            color: isSelected
                                ? _getStatusColor(status).withOpacity(0.3)
                                : Colors.grey[300]!));
                  }).toList()),
              const SizedBox(height: 20),
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ['Single Story', 'Chapter-based', 'Collaborative']
                      .map((type) {
                    final bool isSelected = tempSelectedTypes.contains(type);
                    return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) => setModalState(() => selected
                            ? tempSelectedTypes.add(type)
                            : tempSelectedTypes.remove(type)),
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[700]),
                        side: BorderSide(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.grey[300]!));
                  }).toList()),
              const SizedBox(height: 20),
              const Text('Sort By',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              RadioListTile<StorySortOption>(
                  title: const Text('Last Edited (Newest First)'),
                  value: StorySortOption.lastEditedDesc,
                  groupValue: tempSortOption,
                  onChanged: (v) => setModalState(() => tempSortOption = v!),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              RadioListTile<StorySortOption>(
                  title: const Text('Last Edited (Oldest First)'),
                  value: StorySortOption.lastEditedAsc,
                  groupValue: tempSortOption,
                  onChanged: (v) => setModalState(() => tempSortOption = v!),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              RadioListTile<StorySortOption>(
                  title: const Text('Title (A-Z)'),
                  value: StorySortOption.titleAsc,
                  groupValue: tempSortOption,
                  onChanged: (v) => setModalState(() => tempSortOption = v!),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              RadioListTile<StorySortOption>(
                  title: const Text('Title (Z-A)'),
                  value: StorySortOption.titleDesc,
                  groupValue: tempSortOption,
                  onChanged: (v) => setModalState(() => tempSortOption = v!),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () {
                      context.read<LibraryViewModel>().applyFilters(
                            statuses: tempSelectedStatuses,
                            types: tempSelectedTypes,
                            sort: tempSortOption,
                          );
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Apply Filters'),
                  )),
              const SizedBox(height: 20),
            ],
          )),
        ),
      ),
    );
  }

  void _showStoryOptions(BuildContext context, Story story) {
    final viewModel = context.read<LibraryViewModel>();
    final profileViewModel = context.read<ProfileViewModel>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(story.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 10),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Story'),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToStoryDetail(story);
              }),
          ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(sheetContext);
                final String shareText =
                    'Check out my story: "${story.title}" by ${story.authorName} on Creative Collab! ${story.description != null && story.description!.isNotEmpty ? "\n\n${story.description}" : ""}\n\n#CreativeCollab #Storytelling';
                Share.share(shareText, subject: 'My Story: ${story.title}');
                _showSnackBar('Sharing options opened for "${story.title}"');
              }),
          if (story.status == StoryStatus.draft)
            ListTile(
                leading:
                    const Icon(Icons.publish_outlined, color: Colors.green),
                title: const Text('Publish',
                    style: TextStyle(color: Colors.green)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  bool success = await viewModel.updateStoryStatus(
                      story.id, StoryStatus.published);
                  if (success) {
                    await profileViewModel
                        .refresh(); // Refresh ProfileViewModel
                  }
                  _showSnackBar(
                      success ? 'Story published' : 'Failed to publish story',
                      isError: !success);
                }),
          if (story.status == StoryStatus.published)
            ListTile(
                leading:
                    Icon(Icons.archive_outlined, color: Colors.orange[800]),
                title: Text('Archive',
                    style: TextStyle(color: Colors.orange[800])),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  bool success = await viewModel.updateStoryStatus(
                      story.id, StoryStatus.archived);
                  if (success) {
                    await profileViewModel
                        .refresh(); // Refresh ProfileViewModel
                  }
                  _showSnackBar(
                      success ? 'Story archived' : 'Failed to archive story',
                      isError: !success);
                }),
          if (story.status == StoryStatus.archived)
            ListTile(
                leading:
                    Icon(Icons.unarchive_outlined, color: Colors.blue[700]),
                title: Text('Unarchive',
                    style: TextStyle(color: Colors.blue[700])),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  bool success = await viewModel.updateStoryStatus(
                      story.id, StoryStatus.draft);
                  if (success) {
                    await profileViewModel
                        .refresh(); // Refresh ProfileViewModel
                  }
                  _showSnackBar(
                      success
                          ? 'Story unarchived'
                          : 'Failed to unarchive story',
                      isError: !success);
                }),
          const Divider(),
          ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.tint),
              title: Text('Delete', style: TextStyle(color: AppColors.tint)),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirmation(context, story);
              }),
        ]),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Story story) {
    final viewModel = context.read<LibraryViewModel>();
    final profileViewModel = context.read<ProfileViewModel>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Story?'),
        content: Text(
            'Are you sure you want to permanently delete "${story.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              bool success = await viewModel.deleteStory(story.id);
              if (success) {
                await profileViewModel.refresh(); // Refresh ProfileViewModel
              }
              _showSnackBar(
                  success
                      ? '"${story.title}" deleted'
                      : 'Failed to delete story. ${viewModel.errorMessage ?? ""}',
                  isError: !success);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.tint),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
        backgroundColor: isError ? AppColors.tint : AppColors.primary,
        duration: const Duration(seconds: 3)));
  }

  String _formatDateTimeRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  String _getStatusText(StoryStatus status) {
    switch (status) {
      case StoryStatus.draft:
        return 'Draft';
      case StoryStatus.published:
        return 'Published';
      case StoryStatus.archived:
        return 'Archived';
    }
  }

  Color _getStatusColor(StoryStatus status) {
    switch (status) {
      case StoryStatus.draft:
        return Colors.orange[700]!;
      case StoryStatus.published:
        return Colors.green[700]!;
      case StoryStatus.archived:
        return Colors.blueGrey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (viewModel.isLoading &&
                viewModel.filteredStories.isEmpty &&
                viewModel.errorMessage == null) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            } else if (viewModel.errorMessage != null &&
                viewModel.filteredStories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 50),
                      const SizedBox(height: 15),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () =>
                            viewModel.loadStories(forceRefresh: true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            } else if (viewModel.filteredStories.isNotEmpty) {
              return RefreshIndicator(
                onRefresh: () => viewModel.loadStories(forceRefresh: true),
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: viewModel.filteredStories.length,
                  itemBuilder: (ctx, index) =>
                      _buildStoryItem(ctx, viewModel.filteredStories[index]),
                ),
              );
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: EmptyState(
                    icon: Icons.menu_book,
                    title: viewModel.isSearchActive ||
                            viewModel.selectedStatuses.isNotEmpty ||
                            viewModel.selectedTypes.isNotEmpty
                        ? 'No Matching Stories'
                        : 'Your Library is Empty',
                    message: viewModel.isSearchActive ||
                            viewModel.selectedStatuses.isNotEmpty ||
                            viewModel.selectedTypes.isNotEmpty
                        ? 'Try adjusting your search or filters.'
                        : 'Start creating your first story!',
                    actionLabel: 'Create New Story',
                    onAction: _navigateToCreateScreen,
                  ),
                ),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }
}
