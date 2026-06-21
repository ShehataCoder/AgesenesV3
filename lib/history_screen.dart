import 'dart:io';
import 'package:flutter/material.dart';
import 'core/app_strings.dart';
import 'package:provider/provider.dart';
import 'providers/history_provider.dart';
import 'analysis_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).loadPredictions();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        final query = _searchController.text.toLowerCase();
        final filteredPredictions = historyProvider.predictions.where((pred) {
          final gender = pred['gender'].toString().toLowerCase();
          final age = pred['age'].toString().toLowerCase();
          final timestamp = pred['timestamp'].toString().toLowerCase();
          return gender.contains(query) ||
              age.contains(query) ||
              timestamp.contains(query);
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              AppStrings.getText(context, 'nav_history'),
              style: const TextStyle(
                color: Color(0xFF2962FF),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: AppStrings.getText(context, 'search_hint'),
                      hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF9E9E9E),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                // History List
                Expanded(
                  child: historyProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredPredictions.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.getText(context, 'no_history'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredPredictions.length,
                          itemBuilder: (context, index) {
                            final record = filteredPredictions[index];
                            final imagePath = record['image_path'] as String;
                            final gender = record['gender'] as String;
                            final age = record['age'] as String;
                            final timestamp = DateTime.parse(
                              record['timestamp'] as String,
                            );

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnalysisDetailsScreen(
                                      prediction: record,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[800],
                                        image: DecorationImage(
                                          image: FileImage(File(imagePath)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Text Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "$gender, $age years",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16.0,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(timestamp),
                                            style: const TextStyle(
                                              color: Color(0xFF9E9E9E),
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Delete Icon
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors
                                            .red, // Or use a theme color if preferred, but user spec said red icon in dialog, usually red in list too or grey. User said "add a IconButton ... to the trailing side". Let's stick to theme or grey, but usually delete is red. The dialog icon is red. Let's use grey for the list item to match the arrow, or maybe just the icon.
                                        // User request: "In the ListView items, add a IconButton with the icon Icons.delete_outline to the trailing side (or next to the arrow)."
                                      ),
                                      onPressed: () {
                                        final id = record['id'] as int;
                                        _showDeleteConfirmationDialog(
                                          context,
                                          id,
                                          imagePath,
                                        );
                                      },
                                    ),
                                    // Arrow Icon
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');

    return "$month ${date.day}, ${date.year}, $hour:$minute $amPm";
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    int id,
    String imagePath,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        insetPadding: const EdgeInsets.all(24.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF3E2726),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFD32F2F),
                  size: 32,
                ),
              ),
              // Title
              const Text(
                "Confirm Deletion",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              // Body Text
              Container(
                margin: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                child: const Text(
                  "Are you sure you want to delete this item? This action cannot be undone.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2E),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Delete Button
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        // 1. Pop Dialog Immediately
                        Navigator.pop(context);

                        // 2. Perform Delete
                        try {
                          await Provider.of<HistoryProvider>(
                            context,
                            listen: false,
                          ).deletePrediction(id, imagePath);
                        } catch (e) {
                          // Fail silently or show toast if needed, but error is logged in Provider
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
