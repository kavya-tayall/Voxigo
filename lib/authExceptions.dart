
class UsernameAlreadyExistsException implements Exception {
  final String message;

  UsernameAlreadyExistsException([this.message = 'Username already exists']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}
class UserNotParentException implements Exception {
  final String message;

  UserNotParentException([this.message = 'User is not a parent']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}
class ParentDoesNotExistException implements Exception {
  final String message;

  ParentDoesNotExistException(
      [this.message = 'Email or password is incorrect']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}
class ChildDoesNotExistException implements Exception {
  final String message;

  ChildDoesNotExistException(
      [this.message = 'Username or password is incorrect']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}
class OtherError implements Exception {
  final String message;

  OtherError(
      [this.message = 'Other error']);

  @override
  String toString() {
    return "CustomException: $message";
  }
}


