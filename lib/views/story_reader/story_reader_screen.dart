// views/story_reader/story_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/viewmodel/story_reader_viewmodel.dart';
import 'package:collabwrite/core/constants/colors.dart';
import 'package:collabwrite/core/utils/date_formatter.dart'; // Import the formatter
import 'package:collabwrite/data/models/user_model.dart' as app_user;
import 'package:share_plus/share_plus.dart';

class StoryReaderScreen extends StatelessWidget {
  final Story story;

  const StoryReaderScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Initialize ViewModel, which might fetch more details if needed
      create: (_) => StoryReaderViewModel(story: story)..initialize(),
      child: Consumer<StoryReaderViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            body: viewModel.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _buildStoryContent(context, viewModel),
            bottomNavigationBar: viewModel.isLoading
                ? null
                : _buildBottomActionBar(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildStoryContent(
      BuildContext context, StoryReaderViewModel viewModel) {
    // Use the potentially updated story from the ViewModel
    final story = viewModel.story;
    final author = viewModel.author; // Author fetched by ViewModel

    // Determine the date string to display
    String displayDate;
    if (story.status == StoryStatus.published && story.publishedDate != null) {
      // Use absolute date for published stories
      displayDate =
          'Published ${DateFormatter.formatAbsoluteDate(story.publishedDate)}';
    } else {
      // For drafts or archived, show last edited date (absolute format here)
      displayDate =
          'Updated ${DateFormatter.formatAbsoluteDate(story.lastEdited)}';
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250.0,
          floating: false,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            titlePadding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            title: Text(
              story.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            background: story.coverImage != null && story.coverImage!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // Use a FadeInImage for smoother loading
                      FadeInImage.assetNetwork(
                        placeholder:
                            'assets/images/placeholder_cover.png', // Add a placeholder asset
                        image: story.coverImage!,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) =>
                            Container(
                                color: AppColors.secondary,
                                child: const Icon(Icons.broken_image,
                                    color: AppColors
                                        .textGrey)), // Fallback for network errors
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: AppColors.secondary,
                    child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: AppColors.textGrey, size: 60)),
                  ), // Placeholder if no cover image
          ),
          actions: [
            IconButton(
              icon: Icon(
                viewModel.isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              tooltip: viewModel.isSaved ? 'Remove Bookmark' : 'Bookmark',
              onPressed: () => viewModel.toggleSaveStory(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              tooltip: 'More options',
              onPressed: () {/* TODO: Implement more options menu */},
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Author Section (if author data is available)
                if (author != null) ...[
                  _buildAuthorSection(context, author, viewModel),
                  const SizedBox(height: 16), // Spacing after author
                ] else ...[
                  // Show basic author name if author details failed to load
                  Text('By ${story.authorName}',
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                ],

                // Metadata Row
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Align items vertically
                  children: [
                    _buildInfoChip(Icons.thumb_up_alt_outlined,
                        "${viewModel.likesCount} Likes"),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.visibility_outlined,
                        "${viewModel.viewsCount} Views"),
                    const Spacer(),
                    // Display the calculated date string
                    Text(
                      displayDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Spacing before type/genres

                // Display Story Type
                Text(
                  'Type: ${story.storyType}',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                // Display Genres
                if (story.genres.isNotEmpty)
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: story.genres
                        .map((genre) => Chip(
                              label: Text(genre,
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              labelStyle: TextStyle(
                                  color: AppColors.primary), // Darker label
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 0), // Adjust padding
                            ))
                        .toList(),
                  ),
                const Divider(height: 30, thickness: 0.8),

                // Display Story Content
                // Use the content from the ViewModel, which might be loaded dynamically
                viewModel.storyContent.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                            child: Text("Content not available.",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic))),
                      )
                    : MarkdownBody(
                        data: viewModel.storyContent,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                              fontSize: 17,
                              height: 1.65,
                              color: Color(0xFF333333)),
                          h1: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.background,
                              height: 1.8),
                          h2: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.background,
                              height: 1.8),
                          h3: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.background,
                              height: 1.8),
                          // Add more styles as needed
                          blockquoteDecoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border(
                                left: BorderSide(
                                    color: Colors.grey[300]!, width: 4)),
                          ),
                          blockquotePadding: const EdgeInsets.all(12),
                          code: TextStyle(
                              backgroundColor: Colors.grey[200],
                              fontFamily: "monospace",
                              fontSize: 15),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          codeblockPadding: const EdgeInsets.all(10),
                          listBulletPadding: const EdgeInsets.only(
                              left: 4, top: 4), // Adjust bullet padding
                        ),
                      ),
                const SizedBox(height: 50), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  // _buildAuthorSection: Ensure it handles null author.profileImage correctly
  Widget _buildAuthorSection(BuildContext context, app_user.User? author,
      StoryReaderViewModel viewModel) {
    // This check is now done before calling the function in _buildStoryContent
    // if (author == null) {
    //   return const SizedBox.shrink(); // Or display 'Author Unknown'
    // }

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.secondary, // Background for placeholder
          backgroundImage:
              author!.profileImage != null && author.profileImage!.isNotEmpty
                  ? NetworkImage(author.profileImage!)
                  : null, // Use null for NetworkImage if no URL
          child: (author.profileImage == null || author.profileImage!.isEmpty)
              ? Text(
                  // Display initials only if no image URL
                  author.name.isNotEmpty ? author.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 20, color: Colors.white))
              : null, // Render nothing if NetworkImage is loading/failed
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.name,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background),
              ),
              if (author.bio.isNotEmpty) // Only show bio if it exists
                Text(
                  author.bio,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Follow Button (logic seems okay, relies on ViewModel state)
        OutlinedButton(
          onPressed: () => viewModel.toggleFollowAuthor(),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                viewModel.isFollowingAuthor ? Colors.white : AppColors.primary,
            backgroundColor: viewModel.isFollowingAuthor
                ? AppColors.primary
                : Colors.transparent,
            side: BorderSide(color: AppColors.primary.withOpacity(0.7)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(viewModel.isFollowingAuthor ? 'Following' : 'Follow'),
        ),
      ],
    );
  }

  // _buildInfoChip remains the same
  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey[800])),
      ],
    );
  }

  // _buildBottomActionBar remains the same
  Widget _buildBottomActionBar(
      BuildContext context, StoryReaderViewModel viewModel) {
    return Material(
      elevation: 8.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color ??
              Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionButton(
              context,
              icon: viewModel.isLiked
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              label: '${viewModel.likesCount}', // Use likesCount from VM
              color: viewModel.isLiked ? AppColors.primary : Colors.grey[700],
              onPressed: () => viewModel.toggleLike(),
            ),
            _actionButton(
              context,
              icon: Icons.comment_outlined,
              label: 'Comment', // Replace with comment count later if available
              color: Colors.grey[700],
              onPressed: () {/* TODO: Implement comment screen navigation */},
            ),
            _actionButton(
              context,
              icon: Icons.share_outlined,
              label: 'Share',
              color: Colors.grey[700],
              onPressed: () {
                // Use details from ViewModel's story object
                final String shareText =
                    'Check out this story: "${viewModel.story.title}" by ${viewModel.story.authorName} on CollabWrite!\n${viewModel.story.description ?? ""}\n#CollabWriteApp';
                Share.share(shareText,
                    subject: 'Story: ${viewModel.story.title}');
              },
            ),
          ],
        ),
      ),
    );
  }

  // _actionButton remains the same
  Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      Color? color,
      VoidCallback? onPressed}) {
    return TextButton.icon(
      icon: Icon(icon,
          color: color ?? Theme.of(context).iconTheme.color, size: 20),
      label: Text(label,
          style: TextStyle(
              color: color ?? Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 13)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
