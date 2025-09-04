// views/home/home_screen.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/assets.dart';
import '../../services/auth_service.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../create/create_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/filter_widget.dart';
import '../widgets/story_card.dart';
import '../story_reader/story_reader_screen.dart';
import '../../data/models/story_model.dart'; // For type hints

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // HomeViewModel is now created by ChangeNotifierProvider in build method.
  // Its constructor calls loadCurrentUserAndFetchStories.

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
      const ProfileScreen()
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          HomeViewModel(), // HomeViewModel constructor now initiates data load
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          // Sync _searchController text if viewModel.searchQuery is cleared externally (e.g. filter change)
          // This is a common pattern if the source of truth for search query is in VM
          // and you want the TextField to reflect it.
          if (_searchController.text != viewModel.searchQuery) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Check mounted to avoid calling setState on a disposed widget,
              // though less likely here as it's within build.
              if (mounted) {
                _searchController.text = viewModel.searchQuery;
                // Move cursor to end
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              }
            });
          }

          return Scaffold(
            body: SafeArea(
              child: _buildBody(context, viewModel),
            ),
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: _selectedNavIndex,
              onItemTapped: _onNavItemTapped,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading &&
        viewModel.stories.isEmpty &&
        viewModel.errorMessage == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (viewModel.errorMessage != null &&
        viewModel.stories.isEmpty &&
        viewModel.searchQuery.isEmpty) {
      // Only show full screen error if no search query is active, otherwise search might just yield no results
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 50),
              const SizedBox(height: 15),
              Text('Could not load stories',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700])),
              const SizedBox(height: 8),
              Text(viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => viewModel
                    .refreshHomeScreenData(), // This will re-trigger the full load
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    // Determine if we should show "No stories" message
    bool showNoStoriesMessage =
        viewModel.stories.isEmpty && !viewModel.isLoading;
    String noStoriesText = viewModel.searchQuery.isNotEmpty
        ? "No stories found for '${viewModel.searchQuery}'."
        : (viewModel.selectedFilter != 1 // Assuming 1 is 'Trending' or default
            ? "No stories found for the selected filter."
            : "No stories available.");

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshHomeScreenData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: AppColors.background),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 10),
                    _buildSearchBar(viewModel), // Pass viewModel
                    FilterWidget(
                      filterNames: viewModel.filters,
                      selectedFilter: viewModel.selectedFilter,
                      onFilterSelected: (index) {
                        // Optionally clear search when changing main filter
                        // _searchController.clear();
                        // viewModel.updateSearchQuery('');
                        viewModel.selectFilter(index);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Explore Featured Stories',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    const Text('A collection of must-read stories.',
                        style: TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500)),
                    SizedBox(
                      height: 320,
                      child: (showNoStoriesMessage &&
                              viewModel.stories
                                  .isEmpty) // Check stories for this section
                          ? Center(
                              child: Text(
                                  noStoriesText, // Use dynamic no stories text
                                  style: const TextStyle(
                                      color: AppColors.textGrey)))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              // For featured, perhaps show from _allFetchedStories if search active, or a specific featured list
                              // For simplicity, still using viewModel.stories but limiting count
                              itemCount: viewModel.stories.length > 5
                                  ? 5
                                  : viewModel.stories.length,
                              itemBuilder: (context, index) {
                                final storyItem = viewModel.stories[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(top: 15, right: 10),
                                  child: StoryCard(
                                    story: storyItem,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StoryReaderScreen(
                                              story: storyItem),
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          Provider.of<HomeViewModel>(context,
                                                  listen: false)
                                              .refreshHomeScreenData();
                                          if (kDebugMode)
                                            print(
                                                "HomeScreen: Returned from StoryReader, refreshing home screen stories.");
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                      'Personalized for You', // Or "All Stories" if search/filter active
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(
                      // Dynamic subtitle based on search/filter
                      viewModel.searchQuery.isNotEmpty
                          ? "Search results for '${viewModel.searchQuery}'"
                          : viewModel.selectedFilter != 1
                              ? "Filtered stories"
                              : 'Stories tailored to your interests and reading habits.',
                      style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 15),
                  (showNoStoriesMessage && viewModel.stories.isEmpty)
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                          child: Text(
                              noStoriesText, // Use dynamic no stories text
                              style:
                                  const TextStyle(color: AppColors.textGrey)),
                        ))
                      : GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: viewModel.stories.length,
                          itemBuilder: (context, index) {
                            final storyItem = viewModel.stories[index];
                            return StoryCard(
                              story: storyItem,
                              isGridItem: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StoryReaderScreen(story: storyItem),
                                  ),
                                ).then((_) {
                                  if (mounted) {
                                    Provider.of<HomeViewModel>(context,
                                            listen: false)
                                        .refreshHomeScreenData();
                                    if (kDebugMode)
                                      print(
                                          "HomeScreen: Returned from StoryReader, refreshing home screen stories.");
                                  }
                                });
                              },
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // User's name and avatar could be fetched from AuthService/ProfileViewModel
    // For now, keeping it static as per original.
    return Row(
      children: [
        const CircleAvatar(
            radius: 25, backgroundColor: Colors.white), // Placeholder color
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Hello!', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 5),
              SvgPicture.asset(AppAssets.wavingHand)
            ]),
            const SizedBox(height: 2),
            const Text('Aranav Kumar', // This should be dynamic
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        const Spacer(),
        IconButton(
          // Making notification icon tappable (optional)
          icon: SvgPicture.asset(AppAssets.notification),
          onPressed: () {
            // TODO: Navigate to notifications screen or show dialog
            if (kDebugMode) print("Notification icon tapped");
          },
        )
      ],
    );
  }

  Widget _buildSearchBar(HomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Find stories, writers, or inspiration...',
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          prefixIcon: Padding(
            padding:
                const EdgeInsets.all(12.0), // Adjust padding for visual balance
            child: SvgPicture.asset(
              AppAssets.search,
              colorFilter:
                  const ColorFilter.mode(AppColors.textGrey, BlendMode.srcIn),
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textGrey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    viewModel.updateSearchQuery('');
                    // No need for setState here as viewModel update will trigger rebuild
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.secondary,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10.0), // Adjusted for typical TextField height
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            // Optional: highlight when focused
            borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
          ),
        ),
        onChanged: (query) {
          viewModel.updateSearchQuery(query);
          // Required to make the clear button appear/disappear immediately as user types
          // ViewModel's notifyListeners will rebuild the list, but not necessarily this specific widget part instantly
          // for the suffixIcon state based on _searchController.text.
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}

// ... (rest of the file: _getHeaders, incrementViewCount - unchanged)
Future<Map<String, String>> _getHeaders(
    {bool requireAuth = true, bool isDeleteOrPostNoBody = false}) async {
  final headers = <String, String>{};
  if (!isDeleteOrPostNoBody) {
    headers['Content-Type'] = 'application/json; charset=UTF-8';
  }

  if (requireAuth) {
    final token = await AuthService().getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      if (kDebugMode) {
        print(
            'StoryService Warning: Auth token not found for a route that requires it.');
      }
    }
  }
  return headers;
}

Future<bool> incrementViewCount(int storyId) async {
  final String url = 'http://18.232.150.66:8080/updateStory/$storyId';
  if (kDebugMode) print("StoryService: PATCH $url (increment view)");

  final Map<String, dynamic> requestBody = {
    "id": storyId,
    "title":
        "Placeholder Title (view increment)", // These placeholders might not be ideal for a simple view increment
    "description": "A thrilling tale.",
    "cover_image": "https://example.com/cover.jpg",
    "user_id": 1,
    "likes": 1,
    "views":
        1, // Backend should ideally handle incrementing based on current value
    "published_date": "2025-05-10T10:00:00Z",
    "last_edited": DateTime.now().toUtc().toIso8601String(),
    "story_type": "Fiction",
    "status": "draft",
    "genres": ["Adventure", "Mystery"]
  };
  if (kDebugMode)
    print(
        "StoryService: Payload for incrementViewCount: ${jsonEncode(requestBody)}");

  try {
    final response = await http.patch(Uri.parse(url),
        headers: await _getHeaders(), body: jsonEncode(requestBody));
    if (kDebugMode) {
      print(
          "StoryService: incrementViewCount response ${response.statusCode}, Body: ${response.body}");
    }
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    if (kDebugMode) {
      print('Error incrementing view count for story $storyId: $e');
    }
    return false;
  }
}
