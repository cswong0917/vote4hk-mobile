import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vote4hk_mobile/blocs/app_bloc.dart';
import 'package:vote4hk_mobile/i18n/app_language.dart';
import 'package:vote4hk_mobile/i18n/app_localizations.dart';
import 'package:vote4hk_mobile/models/case.dart';
import 'package:vote4hk_mobile/utils/color.dart';
import 'package:vote4hk_mobile/widgets/stateless/case_card.dart';
import 'package:vote4hk_mobile/services/user_service.dart';

import '../services/user_service.dart';
import '../services/user_service.dart';

// TODO: move this to case page
class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  AnimationController _fadeController;
  Animation _fadeAnimation;
  SharedPreferences _sharedPreferences;
  UserService _userService;
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: Duration(milliseconds: 1000), vsync: this);

    _fadeAnimation = Tween(begin: 1.0, end: 0.0).animate(_fadeController);
    initPlatformState();
    _fadeController.forward();
  }

  initPlatformState() async {
    _userService = FirebaseUserService();
    _userService.notifcationListener(
        this._showNotifcationDialog, this._doNothing);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildDialog(BuildContext context, String message) {
    return AlertDialog(
      content: Text('$message'),
      actions: <Widget>[
        FlatButton(
          child: Icon(Icons.check_circle),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        FlatButton(
          child: Icon(Icons.clear),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  void _showNotifcationDialog(var data) {
    showDialog<bool>(
      context: context,
      builder: (_) => _buildDialog(context, data.toString()),
    ).then((bool shouldNavigate) {
      if (shouldNavigate == true) {
        _doNothing(data);
      }
    });
  }

  void _doNothing(var data) {
    print('_doNothing $data');
  }

  @override
  Widget build(BuildContext context) {
    var appLang = Provider.of<AppLanguage>(context);
    return Stack(
      children: <Widget>[
        Scaffold(
            // TODO: extract to shared instance
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).get('site.title')),
            ),
            drawer: Drawer(
                child: ListView(
                    // Important: Remove any padding from the ListView.
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                  DrawerHeader(
                    child: Text('Drawer Header',
                        style: TextStyle(color: Colors.white)),
                    decoration: BoxDecoration(
                      color: WarsColors.blue,
                    ),
                  ),
                  ListTile(
                    title: appLang.isEng() ? Text('中文') : Text('English'),
                    onTap: () {
                      appLang.changeLanguage(
                          appLang.isEng() ? Locale('zh') : Locale('en'));
                      Navigator.pop(context);
                    },
                  ),
                ])),
            body: StreamBuilder<List<Case>>(
              stream: AppBloc.instance.cases,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                List<Case> cases = snapshot.data;
                return Scaffold(
                  body: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        // in reverse order
                        return Padding(
                            padding: const EdgeInsets.only(
                                bottom: 4.0, left: 8.0, top: 4.0, right: 8.0),
                            child: CaseCard(
                                data: cases[cases.length - 1 - index]));
                      },
                      itemCount: cases?.length ?? 0,
                    ),
                    onRefresh: () async {
                      return Future.delayed(Duration(milliseconds: 1000));
                    },
                  ),
                  resizeToAvoidBottomPadding: false,
                );
              },
            )),
        AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) => _fadeAnimation.value > 0
              ? Container(
                  width: 3000.0,
                  height: 3000.0,
                  decoration: BoxDecoration(
                      color: Theme.of(context)
                          .buttonColor
                          .withAlpha((255 * _fadeAnimation.value).round())),
                )
              : SizedBox(),
        )
      ],
    );
  }
}
