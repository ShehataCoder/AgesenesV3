import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/database_helper.dart';

class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get predictions => _predictions;
  bool get isLoading => _isLoading;

  Future<void> loadPredictions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseHelper.instance.getAllPredictions();
      _predictions = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("Error loading predictions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePrediction(int id, String imagePath) async {
    try {
      // 1. Delete from File System (Safely)
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error deleting file: $e");
      // Continue anyway
    }

    try {
      // 2. Delete from database
      await DatabaseHelper.instance.deletePrediction(id);

      // 3. Update local state
      _predictions.removeWhere((item) => item['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting from DB: $e");
      rethrow;
    }
  }
}
