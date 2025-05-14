import 'package:flutter/material.dart';
import 'package:staff_pos_app/src/interface/style/sizes.dart';
import 'package:staff_pos_app/src/interface/style/spacings.dart';
import 'package:staff_pos_app/src/interface/style/textstyles.dart';

import '../../common/globals.dart' as globals;
// Set up a mock HTTP client.

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Size get preferredSize {
    // We need to use a default size initially, then it will be updated when build is called with context
    return const Size.fromHeight(120);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current screen width using View.of(context) instead of window
    final screenWidth = MediaQuery.of(context).size.width;
    return AppBar(
      toolbarHeight: screenWidth <= 600 ? 60 : 100,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Container(
        padding: EdgeInsets.only(top: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image(
              height: screenWidth <= 600
                      ? sizAppBarPointImageSize
                      : sizAppBarPointImageSizeTablet,
              image: AssetImage('images/icon_header_point.png'),
              fit: BoxFit.cover,
            ),
            if (screenWidth > 600) Container(width: 40),
            TextButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              child: Text(
                globals.appTitle,
                style: screenWidth <= 600
                        ? styleAppBarTitle
                        : styleAppBarTitleTablet,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      //メニュー
      actions: [
        Container(
          padding: screenWidth <= 600
                  ? paddingAppBarAction
                  : paddingAppBarActionTablet,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(0, 4, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      globals.loginName,
                      style: screenWidth <= 600
                              ? styleAppBarActionLabelName
                              : styleAppBarActionLabelNameTablet,
                    ),
                    Text(
                      globals.loginEmail,
                      style: screenWidth <= 600
                              ? styleAppBarActionLabelMail
                              : styleAppBarActionLabelMailTablet,
                    ),
                  ],
                ),
              ),
              // Column(
              //   children: [
              //     Container(
              //       width: MediaQuery.of(context).size.width <= 600
              //           ? sizAppBarAvatarSize
              //           : sizAppBarAvatarSizeTablet,
              //       height: MediaQuery.of(context).size.width <= 600
              //           ? sizAppBarAvatarSize
              //           : sizAppBarAvatarSizeTablet,
              //       decoration: BoxDecoration(
              //         color: Color(0xffc5c5c5),
              //         image: DecorationImage(
              //             image: NetworkImage(
              //                 apiGetStaffAvatarUrl + globals.staffId),
              //             fit: BoxFit.cover),
              //         borderRadius: BorderRadius.circular(50),
              //       ),
              //     )
              //   ],
              // )
            ],
          ),
        ),
      ],
    );
  }
}
