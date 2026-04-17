import 'package:flutter/foundation.dart';
import 'package:yumbook_app/data/mock_restaurants.dart';
import 'package:yumbook_app/models/restaurant.dart';

class SavedRestaurantsStore extends ChangeNotifier {
  SavedRestaurantsStore._();
  static final SavedRestaurantsStore instance = SavedRestaurantsStore._();

  final Map<String, Set<String>> _savedByUser = {};

  Set<String> _savedIdsOf(String userId) {
    return _savedByUser.putIfAbsent(userId, () => <String>{});
  }

  bool isSaved({
    required String userId,
    required String restaurantId,
  }) {
    return _savedIdsOf(userId).contains(restaurantId);
  }

  void toggleSaved({
    required String userId,
    required String restaurantId,
  }) {
    final savedIds = _savedIdsOf(userId);

    if (savedIds.contains(restaurantId)) {
      savedIds.remove(restaurantId);
    } else {
      savedIds.add(restaurantId);
    }

    notifyListeners();
  }

  void removeSaved({
    required String userId,
    required String restaurantId,
  }) {
    final savedIds = _savedIdsOf(userId);
    savedIds.remove(restaurantId);
    notifyListeners();
  }

  List<Restaurant> getSavedRestaurants(String userId) {
    final savedIds = _savedIdsOf(userId);

    return mockRestaurants
        .where((restaurant) => savedIds.contains(restaurant.id))
        .toList();
  }

  int savedCount(String userId) {
    return _savedIdsOf(userId).length;
  }

  void clearUserSaved(String userId) {
    _savedByUser[userId] = <String>{};
    notifyListeners();
  }
}