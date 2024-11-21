import 'package:flutter/material.dart';

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
    if (_isChecked1 & _isChecked2 & _isChecked3 & _isChecked4 & _isChecked5) {
      this._isVisible = false;
      this._animate = true;
    }
    print(_isVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.black,
                        width: 5,
                        style: BorderStyle.solid))),
            child: Padding(
                padding: EdgeInsets.only(bottom: 10, top: 10),
                child: Text(
                  "Calm down with 54321",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )),
          ),
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
                    style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ))),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                    height: 125,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.redAccent,
                        border: Border.all(color: Colors.red, width: 8)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("5 things I can see",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 75,
                              )),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text("Done?",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20))),
                                Checkbox(
                                  value: _isChecked1,
                                  onChanged: (value) {
                                    setState(() {
                                      _isChecked1 = !_isChecked1;
                                      _calmingCheck();
                                    });
                                  },
                                )
                              ],
                            ),
                          )
                        ])),
                Container(
                    height: 125,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orangeAccent,
                        border: Border.all(color: Colors.orange, width: 8)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("4 things I can touch",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 75,
                              )),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text("Done?",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20))),
                                Checkbox(
                                  value: _isChecked2,
                                  onChanged: (value) {
                                    setState(() {
                                      _isChecked2 = !_isChecked2;
                                      _calmingCheck();
                                    });
                                  },
                                )
                              ],
                            ),
                          )
                        ])),
                Container(
                    height: 125,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.lightGreen,
                        border: Border.all(color: Colors.green, width: 8)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("3 things I can hear",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 75,
                              )),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text("Done?",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20))),
                                Checkbox(
                                  value: _isChecked3,
                                  onChanged: (value) {
                                    setState(() {
                                      _isChecked3 = !_isChecked3;
                                      _calmingCheck();
                                    });
                                  },
                                )
                              ],
                            ),
                          )
                        ])),
                Container(
                    height: 125,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.lightBlue,
                        border: Border.all(color: Colors.blue, width: 8)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("2 things I can smell",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 75,
                              )),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text("Done?",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20))),
                                Checkbox(
                                  value: _isChecked4,
                                  onChanged: (value) {
                                    setState(() {
                                      _isChecked4 = !_isChecked4;
                                      _calmingCheck();
                                    });
                                  },
                                )
                              ],
                            ),
                          )
                        ])),
                Container(
                    height: 125,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.pinkAccent,
                        border: Border.all(color: Colors.pink, width: 8)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("1 thing I can taste",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 75,
                              )),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(bottom: 5),
                                    child: Text("Done?",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 20))),
                                Checkbox(
                                  value: _isChecked5,
                                  onChanged: (value) {
                                    setState(() {
                                      _isChecked5 = !_isChecked5;
                                      _calmingCheck();
                                    });
                                  },
                                )
                              ],
                            ),
                          )
                        ]))
              ]),
        ),
      ),
    );
  }
}