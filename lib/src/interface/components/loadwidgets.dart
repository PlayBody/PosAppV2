import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/interface/layout/myappbar.dart';
import 'package:staff_pos_app/src/interface/layout/mydrawer.dart';
import 'package:staff_pos_app/src/interface/layout/subbottomnavi.dart';

// import 'package:syncfusion_flutter_charts/charts.dart';

class LoadBodyWdiget extends StatelessWidget {
  final Future<List<dynamic>>? loadData;
  final Widget render;
  const LoadBodyWdiget({
    required this.loadData,
    required this.render,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: loadData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Center(child: render);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        // By default, show a loading spinner.
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MainBodyWdiget extends StatelessWidget {
  final Widget render;
  final bool? resizeBottom;
  final bool? isFullScreen;
  final Widget? fullScreenButton;
  final double? fullscreenTop;
  const MainBodyWdiget({
    required this.render,
    this.resizeBottom,
    this.isFullScreen,
    this.fullscreenTop,
    this.fullScreenButton,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: resizeBottom ?? true,
        backgroundColor: Colors.transparent,
        appBar:
            (isFullScreen == null || isFullScreen == false) ? MyAppBar() : null,
        body: Stack(
          children: [
            render,
            if (fullScreenButton != null)
              Positioned(
                left: 0,
                top: fullscreenTop ?? 105,
                child: fullScreenButton!,
              ),
          ],
        ),
        drawer: MyDrawer(),
        bottomNavigationBar:
            (isFullScreen == null || isFullScreen == false)
                ? SubBottomNavi()
                : null,
      ),
    );
  }
}
