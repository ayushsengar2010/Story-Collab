import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class FilterWidget extends StatelessWidget {
  final List<String> filterNames;
  final int selectedFilter;
  final Function(int) onFilterSelected;

  const FilterWidget({
    super.key,
    required this.filterNames,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ListView.builder(
          itemCount: filterNames.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => onFilterSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: selectedFilter == index
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selectedFilter == index
                          ? Colors.transparent
                          : AppColors.textGrey),
                ),
                child: Center(
                  child: Text(filterNames[index],
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            );
          }),
    );
  }
}
