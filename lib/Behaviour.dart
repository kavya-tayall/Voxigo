import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_top_bar.dart';
import 'Buttons.dart';
import 'bottom_nav_bar.dart';
import 'EditBar.dart';
import 'homePage.dart';
import 'package:table_calendar/table_calendar.dart';

class BehaviourPage extends StatelessWidget{

  Widget build(BuildContext context){
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: DateTime.now(),
    );
  }
}