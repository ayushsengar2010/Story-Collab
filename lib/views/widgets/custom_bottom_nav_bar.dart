import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/assets.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textGrey,
      type: BottomNavigationBarType.fixed,
      items: [
        _buildNavItem(AppAssets.home, "Home", 0),
        _buildNavItem(AppAssets.create, "Create", 1),
        _buildNavItem(AppAssets.library, "Library", 2),
        _buildNavItem(AppAssets.profile, "Profile", 3),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem(String asset, String label, int index) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        asset,
        color: selectedIndex == index ? AppColors.primary : AppColors.textGrey,
      ),
      label: label,
    );
  }
}
