import 'dart:io';
import 'package:flutter/material.dart';

class AnalysisDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> prediction;

  const AnalysisDetailsScreen({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final imagePath = prediction['image_path'] as String;
    final gender = prediction['gender'] as String;
    final age = prediction['age'] as String;
    final timestamp = DateTime.parse(prediction['timestamp'] as String);
    final formattedDate = _formatDate(timestamp);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark Mode Background
      appBar: AppBar(
        title: const Text('Analysis Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality placeholder
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image Container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Analyzed Date
            Text(
              "Analyzed on $formattedDate",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Estimated Age InfoCard
            _buildInfoCard(label: "Estimated Age", value: "$age years"),

            const SizedBox(height: 10),

            // Estimated Gender InfoCard
            _buildInfoCard(label: "Estimated Gender", value: gender),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
}
