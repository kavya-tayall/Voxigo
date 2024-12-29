class FeelingEntry {
  final String feeling;
  final DateTime timestamp;

  FeelingEntry({required this.feeling, required this.timestamp});
}

class ButtonEntry {
  final String sentence;
  final DateTime timestamp;

  ButtonEntry({required this.sentence, required this.timestamp});
}

class AnonUserData {
  final String userId;
  final List<FeelingEntry> feelings;
  final List<ButtonEntry> buttons;

  AnonUserData({
    required this.userId,
    required this.feelings,
    required this.buttons,
  });
}

class InMemoryAnonUserStore {
  // Static collection for all users
  static final Map<String, AnonUserData> _store = {};

  // Add or update a user
  static void addUser(AnonUserData userData) {
    _store[userData.userId] = userData;
  }

  // Get a user by userId
  static AnonUserData? getUser(String userId) {
    return _store[userId];
  }

  // Delete a user by userId
  static void deleteUser(String userId) {
    _store.remove(userId);
  }

  // Retrieve all users
  static List<AnonUserData> getAllUsers() {
    return _store.values.toList();
  }

  // Check if a user exists
  static bool containsUser(String userId) {
    return _store.containsKey(userId);
  }

  // Clear all data
  static void clear() {
    _store.clear();
  }
}
