// widgets/story_card.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart'; // Assuming this path is correct
import '../../../data/models/story_model.dart';
import '../../services/auth_service.dart'; // Assuming this path is correct
import 'package:http/http.dart' as http;

class StoryCard extends StatelessWidget {
  final Story story;
  final bool isGridItem;
  final VoidCallback? onTap;

  StoryCard({
    super.key,
    required this.story,
    this.isGridItem = false,
    this.onTap,
  });
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final double imageHeight = isGridItem ? 100 : 120;
    final double titleSize = isGridItem ? 14 : 16;
    final double authorSize = isGridItem ? 12 : 14;
    final double descriptionSize = isGridItem ? 10 : 12;
    final double statsSize = 11;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isGridItem ? null : 200,
        margin: isGridItem ? EdgeInsets.zero : const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color:
              AppColors.secondary, // Make sure AppColors.secondary is defined
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for Column height
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: imageHeight,
                width: double.infinity,
                color:
                    AppColors.textGrey.withOpacity(0.2), // Placeholder bg color
                child: story.coverImage != null && story.coverImage!.isNotEmpty
                    // IMPORTANT: If story.coverImage is a URL from the backend, use Image.network
                    // If it's a local asset path (e.g., from dummy data or CreateScreen picker *preview*),
                    // then Image.asset or Image.file is appropriate.
                    // For data from API, it's almost always Image.network.
                    ? (story.coverImage!.startsWith('http') ||
                            story.coverImage!.startsWith('https')
                        ? Image.network(
                            story.coverImage!,
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image_outlined, // Changed icon
                                  color: AppColors.textGrey,
                                  size: imageHeight * 0.4,
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            // Fallback to asset if not a URL (common for dummy data)
                            story.coverImage!,
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textGrey,
                                  size: imageHeight * 0.4,
                                ),
                              );
                            },
                          ))
                    : Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textGrey,
                          size: imageHeight * 0.4,
                        ),
                      ),
              ),
            ),
            Expanded(
              // Use Expanded to make the text content take available vertical space
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Distribute space
                  children: [
                    Column(
                      // Group for title, author, description
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(
                            height: isGridItem ? 2 : 4), // Adjusted spacing
                        Text(
                          story.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: authorSize,
                          ),
                        ),
                        SizedBox(
                            height: isGridItem ? 2 : 4), // Adjusted spacing
                        if (story.description != null &&
                            story.description!.isNotEmpty)
                          Text(
                            story.description!,
                            maxLines: isGridItem
                                ? 2
                                : (isGridItem
                                    ? 2
                                    : 2), // Max 2 lines for description for consistency
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textGrey
                                  .withOpacity(0.9), // Slightly less dim
                              fontSize: descriptionSize,
                              height: 1.3,
                            ),
                          ),
                      ],
                    ),
                    // Pushes stats to the bottom if there's space
                    // If not enough space (e.g. long desc), it will be just below desc
                    const Spacer(
                        flex:
                            1), // Add spacer to push stats down if possible in list view
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 6.0), // Add some top padding to stats
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildStatIcon(
                            Icons.favorite,
                            Colors.redAccent[100]!, // Softer red
                            story.likes,
                            statsSize,
                          ),
                          const SizedBox(width: 15),
                          _buildStatIcon(
                            Icons.visibility,
                            Colors.blueAccent[100]!, // Softer blue
                            story.views,
                            statsSize,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(
      IconData icon, Color color, int value, double textSize) {
    return Row(
      children: [
        Icon(icon, color: color, size: textSize + 2), // Slightly smaller icon
        const SizedBox(width: 3),
        Text(
          _formatCount(value),
          style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: textSize - 1), // Slightly smaller text
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
    }
    return count.toString();
  }
}
