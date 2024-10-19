import 'package:whereisthetoilet/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final GlobalKey<FormState> formKey;
  final Size size;
  final ValueChanged<String>?
      onSearch; // Change to ValueChanged<String> for search callback

  const CustomSearchBar({
    super.key,
    required this.searchController,
    required this.formKey,
    required this.size,
    this.onSearch,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    double width = widget.size.width;
    double height = widget.size.height;
    double screenRatio = height / width;
    return Container(
      width: width,
      height: height * 0.06,
      decoration: BoxDecoration(
        color: AppColors.crimsonRed,
        borderRadius: BorderRadius.circular(screenRatio * 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.backgroundCharcoalGray.withOpacity(0.04),
            blurRadius: screenRatio * 2,
            offset: Offset(0, screenRatio * 2),
          ),
        ],
      ),
      margin: EdgeInsets.all(screenRatio * 4),
      child: Form(
        key: widget.formKey,
        child: Center(
          child: TextFormField(
            controller: widget.searchController,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: AppColors.lightGrayText, // Set typed text color to white
              fontSize: screenRatio * 7,
            ),
            decoration: InputDecoration(
              suffixIcon: GestureDetector(
                onTap: () {
                  if (widget.onSearch != null) {
                    widget.onSearch!(widget
                        .searchController.text); // Trigger search on icon tap
                  }
                },
                child: const Icon(
                  Icons.search,
                  color: AppColors.lightGrayText,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenRatio * 8,
                vertical: screenRatio * 4,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(screenRatio * 4),
              ),
              hintText: 'Seacrch for toilets/washrooms near you',
              hintStyle: TextStyle(
                color: AppColors.lightGrayText,
                fontSize: screenRatio * 7,
                fontWeight: FontWeight.normal,
                fontFamily: 'Roboto',
              ),
            ),
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) {
              if (widget.onSearch != null) {
                widget.onSearch!(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
