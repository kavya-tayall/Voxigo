import 'package:flutter/material.dart';
import 'package:test_app/child_pages/Five_things_to_see.dart';
import 'package:test_app/auth_logic.dart';
import 'package:test_app/user_session_management.dart';

class FiveCalmDownHome extends StatefulWidget {
  FiveCalmDownHome({super.key});

  @override
  State<FiveCalmDownHome> createState() => _FiveCalmDownHomeState();
}

class _FiveCalmDownHomeState extends State<FiveCalmDownHome> {
  bool _isChecked1 = false;
  bool _isChecked2 = false;
  bool _isChecked3 = false;
  bool _isChecked4 = false;
  bool _isChecked5 = false;
  bool _isVisible = true;
  bool _animate = false;

  void _calmingCheck() {
    if (_isChecked1 &&
        _isChecked2 &&
        _isChecked3 &&
        _isChecked4 &&
        _isChecked5) {
      setState(() {
        _isVisible = false;
        _animate = true;
      });
    }
    print(_isVisible);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    if (isSessionValid == false) {
      return SessionExpiredWidget(
        onLogout: () => logOutUser(context),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calm Down with 54321",
          textAlign: TextAlign.center,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Visibility(
          visible: _isVisible,
          replacement: AnimatedOpacity(
            opacity: _animate ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1800),
            child: Center(
              child: Text(
                "All Done!",
                style: TextStyle(
                  fontSize: isMobile ? 60 : 100,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildCheckBox(
                "5 things I can see",
                Colors.redAccent,
                Colors.red,
                _isChecked1,
                (value) {
                  setState(() {
                    _isChecked1 = value!;
                    _calmingCheck();
                  });
                },
                isMobile,
              ),
              _buildCheckBox(
                "4 things I can touch",
                Colors.orangeAccent,
                Colors.orange,
                _isChecked2,
                (value) {
                  setState(() {
                    _isChecked2 = value!;
                    _calmingCheck();
                  });
                },
                isMobile,
              ),
              _buildCheckBox(
                "3 things I can hear",
                Colors.lightGreen,
                Colors.green,
                _isChecked3,
                (value) {
                  setState(() {
                    _isChecked3 = value!;
                    _calmingCheck();
                  });
                },
                isMobile,
              ),
              _buildCheckBox(
                "2 things I can smell",
                Colors.lightBlue,
                Colors.blue,
                _isChecked4,
                (value) {
                  setState(() {
                    _isChecked4 = value!;
                    _calmingCheck();
                  });
                },
                isMobile,
              ),
              _buildCheckBox(
                "1 thing I can taste",
                Colors.pinkAccent,
                Colors.pink,
                _isChecked5,
                (value) {
                  setState(() {
                    _isChecked5 = value!;
                    _calmingCheck();
                  });
                },
                isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckBox(String title, Color color, Color borderColor,
      bool isChecked, ValueChanged<bool?> onChanged, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        height: 125,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color,
          border: Border.all(color: borderColor, width: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              flex: 3,
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 25 : 45,
                  overflow: TextOverflow.ellipsis,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      "Done?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: isMobile ? 14 : 20,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isChecked,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
