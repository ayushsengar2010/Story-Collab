// views/collaboration/collaboration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting

import 'package:collabwrite/core/constants/colors.dart';
import 'package:collabwrite/data/models/story_model.dart';
import 'package:collabwrite/data/models/author_model.dart'; // Import Author model
import 'package:collabwrite/viewmodel/collaboration_viewmodel.dart';
import 'package:collabwrite/views/widgets/custom_bottom_nav_bar.dart';
// Import other screens for bottom nav
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:collabwrite/views/create/create_screen.dart';
import 'package:collabwrite/views/library/library_screen.dart';
import 'package:collabwrite/views/profile/profile_screen.dart';

class CollaborationScreen extends StatelessWidget {
  final Story story; // Passed in story object

  const CollaborationScreen({super.key, required this.story});

  static const String routeName = '/collaboration';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Pass the initial story to the ViewModel
      create: (_) => CollaborationViewModel(story: story),
      child: const _CollaborationScreenContent(),
    );
  }
}

class _CollaborationScreenContent extends StatefulWidget {
  const _CollaborationScreenContent();

  @override
  State<_CollaborationScreenContent> createState() =>
      _CollaborationScreenContentState();
}

class _CollaborationScreenContentState
    extends State<_CollaborationScreenContent> {
  final int _initialSelectedNavIndex =
      2; // Assuming index 2 is relevant context

  void _onNavItemTapped(
      BuildContext context, int index, CollaborationViewModel viewModel) {
    if (index == _initialSelectedNavIndex) return;
    // Maybe check for unsaved collaboration settings changes here in the future
    _navigateToScreen(context, index, viewModel.storyObjectForViewModel);
  }

  void _navigateToScreen(
      BuildContext context, int index, Story currentStoryState) {
    final screens = [
      const HomeScreen(),
      const CreateScreen(),
      const LibraryScreen(), // Library screen should fetch its own data
      const ProfileScreen(),
    ];
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => screens[index],
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  // --- Invite Dialog ---
  void _showInviteDialog(
      BuildContext context, CollaborationViewModel viewModel) {
    final TextEditingController emailController = TextEditingController();
    // Capture the ScaffoldMessenger before the dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Invite Collaborator'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
                hintText: 'Enter collaborator email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty && email.contains('@')) {
                  // Basic email validation
                  Navigator.pop(dialogContext); // Close dialog first
                  bool success = await viewModel.inviteCollaborator(email);
                  // Use the captured ScaffoldMessenger
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Invitation sent to $email.'
                          : viewModel.collaboratorError ??
                              'Failed to send invitation.'),
                      backgroundColor: success ? Colors.green : AppColors.tint,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  // Show error using the captured ScaffoldMessenger
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address'),
                      backgroundColor: AppColors.tint,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Invite'),
            ),
          ],
        );
      },
    );
  }

  // --- Remove Confirmation Dialog ---
  void _showRemoveConfirmationDialog(BuildContext context,
      CollaborationViewModel viewModel, Author collaboratorToRemove) {
    // Capture ScaffoldMessenger before the dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Check owner status using the ViewModel's story object for reliability
    if (collaboratorToRemove.id.toString() ==
        viewModel.storyObjectForViewModel.authorId) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the story owner.'),
          backgroundColor: AppColors.tint,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Remove Collaborator?'),
          content: Text(
              'Are you sure you want to remove ${collaboratorToRemove.name} (${collaboratorToRemove.email}) from this story?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.tint),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                bool success =
                    await viewModel.removeCollaborator(collaboratorToRemove.id);
                // Use captured ScaffoldMessenger
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '${collaboratorToRemove.name} removed.'
                        : viewModel.collaboratorError ??
                            'Failed to remove collaborator.'),
                    backgroundColor: success ? Colors.green : AppColors.tint,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  // --- Helper Methods ---
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer for easy access to viewModel and automatic rebuilds
    return Consumer<CollaborationViewModel>(
      builder: (context, viewModel, child) {
        return WillPopScope(
          onWillPop: () async {
            // Pass back the potentially modified story state when using system back gesture
            Navigator.of(context).pop(viewModel.storyObjectForViewModel);
            return false; // We handled the pop manually
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1.0,
              shadowColor: Colors.grey[200],
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.background),
                // Pass back state on AppBar back button press
                onPressed: () => Navigator.of(context)
                    .pop(viewModel.storyObjectForViewModel),
              ),
              title: const Text('Collaboration',
                  style: TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            body: RefreshIndicator(
              onRefresh: () =>
                  viewModel.loadCollaborators(), // Allow pull-to-refresh
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Ensure scrollable even when content fits
                padding: const EdgeInsets.fromLTRB(
                    16.0, 16.0, 16.0, 80.0), // Padding for content + bottom nav
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Story Info Banner (Uses ViewModel getters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(viewModel.storyTitle,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Chip(
                            label: Text(
                                '${viewModel.chapterCount} ${viewModel.chapterCount == 1 ? "Chapter" : "Chapters"}', // Handle pluralization
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            labelPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tabs
                    Row(
                      children: [
                        Expanded(
                            child: _TabButton(
                                label: 'Collaborators',
                                isSelected: viewModel.selectedTab ==
                                    CollaborationTab.collaborators,
                                onTap: () => viewModel.selectTab(
                                    CollaborationTab.collaborators))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _TabButton(
                                label: 'Version History',
                                isSelected: viewModel.selectedTab ==
                                    CollaborationTab.versionHistory,
                                onTap: () => viewModel.selectTab(
                                    CollaborationTab.versionHistory))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tab Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: viewModel.selectedTab ==
                              CollaborationTab.collaborators
                          ? _buildCollaboratorsTab(
                              context, viewModel) // Pass context and viewModel
                          : _buildVersionHistoryTab(context, viewModel),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: _initialSelectedNavIndex,
              onItemTapped: (index) =>
                  _onNavItemTapped(context, index, viewModel),
            ),
          ),
        );
      },
    );
  }

  // --- BUILD COLLABORATORS TAB (Updated) ---
  Widget _buildCollaboratorsTab(
      BuildContext context, CollaborationViewModel viewModel) {
    // Get owner ID from the initial story object held by the view model
    final storyOwnerId = viewModel.storyObjectForViewModel.authorId;

    return Column(
      key: const ValueKey('collaboratorsTab'), // For AnimatedSwitcher
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Collaborators',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 20, color: AppColors.tint),
              label: const Text('Invite+',
                  style: TextStyle(
                      color: AppColors.tint, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => _showInviteDialog(
                  context, viewModel), // Use context from builder
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Handle Loading State
        if (viewModel.isLoadingCollaborators)
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: CircularProgressIndicator(color: AppColors.primary)))
        // Handle Error State
        else if (viewModel.collaboratorError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.tint, size: 30),
                SizedBox(height: 8),
                Text(viewModel.collaboratorError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.tint)),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => viewModel.loadCollaborators(),
                  child:
                      Text("Retry", style: TextStyle(color: AppColors.primary)),
                )
              ],
            )),
          )
        // Handle Empty State (after loading and no error)
        else if (viewModel.collaborators.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30.0),
            child:
                Center(child: Text('No collaborators found for this story.')),
          )
        // Display Collaborator List
        else
          ListView.builder(
            shrinkWrap: true, // Important inside SingleChildScrollView
            physics:
                const NeverScrollableScrollPhysics(), // Disable internal scrolling
            itemCount: viewModel.collaborators.length,
            itemBuilder: (ctx, index) {
              final collaborator = viewModel.collaborators[index];
              // Compare collaborator ID (int) with owner ID (String) safely
              final bool isOwner = collaborator.id.toString() == storyOwnerId;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0.5,
                color: Colors.white, // Use white for better contrast maybe
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: collaborator.profileImage != null &&
                            collaborator.profileImage!.isNotEmpty
                        ? NetworkImage(collaborator.profileImage!)
                            as ImageProvider // Cast for type safety
                        : null,
                    child: (collaborator.profileImage == null ||
                            collaborator.profileImage!.isEmpty)
                        ? Text(
                            collaborator.name.isNotEmpty
                                ? collaborator.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(collaborator.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (isOwner)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Tooltip(
                            message: "Story Owner",
                            child: Icon(Icons.star_rounded,
                                color: Colors.amber.shade700, size: 18),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    collaborator.email, // Display email
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  // --- Remove Button ---
                  trailing: isOwner
                      ? null // Don't show remove button for the owner
                      : IconButton(
                          icon: Icon(Icons.person_remove_outlined,
                              color: AppColors.tint.withOpacity(0.8), size: 20),
                          tooltip: 'Remove Collaborator',
                          onPressed: () => _showRemoveConfirmationDialog(
                              context, viewModel, collaborator),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                ),
              );
            },
          ),

        // --- Settings and Pending Reviews Section (Keep existing implementation) ---
        const SizedBox(height: 25),
        const Text('Collaboration Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _SettingItem(
          title: 'Shareable Link',
          subtitle: 'Anyone with the link can request access',
          isActive: viewModel.isShareableLinkActive,
          onChanged: (value) => viewModel.toggleShareableLink(value),
        ),
        _SettingItem(
          title: 'Review System',
          subtitle: 'Approve edits before publishing',
          isActive: viewModel.isReviewSystemActive,
          onChanged: (value) => viewModel.toggleReviewSystem(value),
        ),

        // --- Pending Review Requests (Keep as is, uses internal _story data) ---
        if (viewModel.pendingReviewRequests.isNotEmpty) ...[
          const SizedBox(height: 25),
          Text(
              'Pending Review Requests (${viewModel.pendingReviewRequests.length})',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.pendingReviewRequests.length,
            itemBuilder: (ctx, index) {
              final request = viewModel.pendingReviewRequests[index];
              // --- Build Pending Request ListTile (Keep existing implementation) ---
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0.5,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: request.userAvatarUrl != null &&
                            request.userAvatarUrl!.isNotEmpty
                        ? NetworkImage(request.userAvatarUrl!) as ImageProvider
                        : null,
                    child: (request.userAvatarUrl == null ||
                            request.userAvatarUrl!.isEmpty)
                        ? Text(
                            request.userName.isNotEmpty
                                ? request.userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(request.details,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'By ${request.userName} • Requested ${_formatRelativeTime(request.requestedDate)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      viewModel.reviewPendingRequest(request.requestId,
                          approve: true);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Request from ${request.userName} marked as reviewed (simulated)'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tint,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('Review', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            },
          ),
        ]
      ],
    );
  }

  // --- BUILD VERSION HISTORY TAB (Keep as is) ---
  Widget _buildVersionHistoryTab(
      BuildContext context, CollaborationViewModel viewModel) {
    return Center(
      key: const ValueKey('versionHistoryTab'), // For AnimatedSwitcher
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_outlined,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'Version History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Track changes, compare versions, and revert to previous states of your story. This feature is coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets (_TabButton, _SettingItem) ---
// Keep these exactly as they were in the previous step.

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.tint : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : AppColors.textGrey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _SettingItem({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.0,
      color: Colors.grey.shade50, // Light background for the switch tile
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        value: isActive,
        onChanged: onChanged,
        activeColor: AppColors.primary, // Use primary color for active switch
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        dense: true, // Make it more compact
      ),
    );
  }
}
