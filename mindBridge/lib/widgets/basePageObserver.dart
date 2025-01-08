import 'package:flutter/widgets.dart';
import 'package:test_app/widgets/globals.dart';

class BasePageObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    // Check if the new route is "BasePage"
    print('Route name: ${route.settings.name}');
    if (route.settings.name == 'BasePage') {
      atBasePage = true;
      print('Navigated to BasePage');
    } else {
      atBasePage = false;
      print('Navigated to another screen');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    print('previousRoute Route name: ${previousRoute?.settings.name}');
    print(route.settings.name);
    // Check if returning to "BasePage"
    if (previousRoute?.settings.name == 'BasePage') {
      atBasePage = true;
      print('Returned to BasePage');
    } else if ((previousRoute == null) ||
        (previousRoute.settings.name == '') ||
        (previousRoute.settings.name == '/') ||
        (route.settings.name == null)) {
      atBasePage = true;
      print('Returned to BasePage');
    }
  }
}
