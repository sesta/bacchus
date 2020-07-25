import 'dart:math';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cellar/domain/entities/status.dart';
import 'package:cellar/domain/entities/user.dart';
import 'package:cellar/domain/entities/drink.dart';
import 'package:cellar/domain/models/timeline.dart';
import 'package:cellar/repository/user_repository.dart';
import 'package:cellar/repository/analytics_repository.dart';
import 'package:cellar/repository/provider/auth.dart';

import 'package:cellar/app/widget/drink_grid.dart';
import 'package:cellar/app/widget/atoms/label_test.dart';
import 'package:cellar/app/widget/atoms/normal_text.dart';
import 'package:cellar/app/widget/atoms/small_text.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  HomePage({
    Key key,
    this.user,
    this.status,
    this.setUser,
  }) : super(key: key);

  final User user;
  final Status status;
  final setUser;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimelineType _timelineType = TimelineType.Mine;
  DrinkType _drinkType;
  OrderType _orderType = OrderType.Newer;

  List<Drink> _publicAllDrinks;
  List<Drink> _mineAllDrinks;
  Map<DrinkType, List<Drink>> _publicDrinkMap = {};
  Map<DrinkType, List<Drink>> _mineDrinkMap = {};

  ScrollController _scrollController = ScrollController();
  CarouselController _carouselController = CarouselController();

  bool _loadingSignIn = false;

  @override
  initState() {
    super.initState();

    _updateTimeline();
  }

  Iterable<MapEntry<int, DrinkType>> get _postedDrinkTypeEntries {
    if (widget.user == null) {
      return DrinkType.values
        .where((drinkType) => _getUploadCount(drinkType) > 0)
        .toList()
        .asMap()
        .entries;
    }

    return widget.user.drinkTypesByMany
      .where((drinkType) => _getUploadCount(drinkType) > 0)
      .toList()
      .asMap()
      .entries;
  }

  Future<void> _updateTimeline({ bool isForceUpdate }) async {
    if (widget.user == null && _timelineType == TimelineType.Mine) {
      return;
    }

    if (
      _getTargetDrinks(_drinkType) != null
      && isForceUpdate != true
    ) {
      return;
    }

    final drinks = await getTimelineDrinks(
      _timelineType,
      _orderType,
      drinkType: _drinkType,
      userId: widget.user == null ? null : widget.user.userId,
    );
    _setDrinks(drinks);
  }

  Future<void> _refresh() async {
    _setDrinks(null);

    AnalyticsRepository().sendEvent(
      EventType.ReloadTimeline,
      {
        'timelineType': _timelineType.toString(),
        'drinkType': _drinkType.toString(),
        'orderType': _orderType.toString(),
      },
    );
    await _updateTimeline(isForceUpdate: true);
  }

  _setDrinks(List<Drink> drinks) {
    if (_drinkType == null) {
      switch(_timelineType) {
        case TimelineType.All:
          setState(() {
            _publicAllDrinks = drinks;
          });
          return;
        case TimelineType.Mine:
          setState(() {
            _mineAllDrinks = drinks;
          });
          return;
      }
    }

    switch(_timelineType) {
      case TimelineType.All:
        setState(() {
          _publicDrinkMap[_drinkType] = drinks;
        });
        return;
      case TimelineType.Mine:
        setState(() {
          _mineDrinkMap[_drinkType] = drinks;
        });
        return;
    }

    throw '予期せぬtypeです。 $_timelineType';
  }

  _updateTimelineType(TimelineType timelineType) {
    if (_timelineType == timelineType) {
      return;
    }

    setState(() {
      _timelineType = timelineType;
      _drinkType = null;
    });

    AnalyticsRepository().sendEvent(
      EventType.ChangeTimelineType,
      {
        'timelineType': timelineType.toString(),
        'drinkType': _drinkType.toString(),
        'orderType': _orderType.toString(),
      },
    );
    _updateTimeline();
  }

  _updateDrinkType(DrinkType drinkType, String from) {
    if (_drinkType == drinkType) {
      return;
    }

    setState(() {
      _drinkType = drinkType;
    });

    AnalyticsRepository().sendEvent(
      EventType.ChangeDrinkType,
      {
        'timelineType': _timelineType.toString(),
        'drinkType': drinkType.toString(),
        'orderType': _orderType.toString(),
        'from': from,
      },
    );
    _updateTimeline();
  }

  _updateOrderType(OrderType orderType) {
    if (_orderType == orderType) {
      return;
    }

    setState(() {
      _orderType = orderType;
      _publicAllDrinks = null;
      _mineAllDrinks = null;
      _publicDrinkMap = {};
      _mineDrinkMap = {};
    });

    AnalyticsRepository().sendEvent(
      EventType.ChangeOrderType,
      {
        'timelineType': _timelineType.toString(),
        'drinkType': _drinkType.toString(),
        'orderType': orderType.toString(),
      },
    );
    _updateTimeline();
  }

  _updateDrink() {
    // editなどによるDrinkの更新を反映させるため
    setState(() {});
  }

  _scrollToDrinkType(int index) {
    _scrollController.animateTo(
      min(index * 80.0, _scrollController.position.maxScrollExtent),
      curve: Curves.easeOut,
      duration: Duration(milliseconds: 300),
    );
  }

  Future<void> _checkSignIn() async {
    setState(() {
      this._loadingSignIn = true;
    });
    final firebaseUser = await signIn();
    if (firebaseUser == null) {
      print('SignInに失敗しました');

      setState(() {
        this._loadingSignIn = false;
      });
      return;
    }

    final userId = await getSignInUserId();
    final user = await UserRepository().getUser(userId);
    setState(() {
      this._loadingSignIn = false;
    });

    if (user != null) {
      widget.setUser(user);
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    Navigator.of(context).pushNamed('/signUp', arguments: userId);
  }

  int _getUploadCount(DrinkType drinkType) {
    if (widget.user == null && _timelineType == TimelineType.Mine) {
      return 0;
    }

    if (drinkType == null) {
      switch(_timelineType) {
        case TimelineType.All:
          return widget.status.uploadCount;
        case TimelineType.Mine:
          return widget.user.uploadCount;
      }
    }

    switch(_timelineType) {
      case TimelineType.All:
        return widget.status.drinkTypeUploadCounts[drinkType.index];
      case TimelineType.Mine:
        return widget.user.uploadCounts[drinkType];
    }

    throw 'timelineTypeの考慮漏れです';
  }

  List<Drink> _getTargetDrinks(DrinkType drinkType) {
    if (drinkType == null) {
      switch(_timelineType) {
        case TimelineType.All: return _publicAllDrinks;
        case TimelineType.Mine: return _mineAllDrinks;
      }
    }

    switch(_timelineType) {
      case TimelineType.All: return _publicDrinkMap[drinkType];
      case TimelineType.Mine: return _mineDrinkMap[drinkType];
    }

    throw '予期せぬtypeです。 $_timelineType';
  }

  Future<void> _movePostPage() async {
    final isPosted = await Navigator.of(context).pushNamed('/post');
    if (isPosted == null) {
      return;
    }

    setState(() {
      _mineAllDrinks = null;
      _mineDrinkMap = {};
    });
    _updateTimeline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              'Cellar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 8)),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 40,
                  child: _drinkTypeList(),
                ),
              ),
              _orderMenu(),
            ],
          ),
          Expanded(
            child: widget.user == null && _timelineType == TimelineType.Mine
              ? _signInContainer()
              : CarouselSlider(
                carouselController: _carouselController,
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height,
                  viewportFraction: 1,
                  enableInfiniteScroll: false,
                  onPageChanged: (int index, CarouselPageChangedReason reason) {
                    if (reason == CarouselPageChangedReason.controller) {
                      return;
                    }

                    if (index == 0) {
                      _updateDrinkType(null, 'carousel');
                      _scrollToDrinkType(0);
                      return;
                    }

                    final targetDrinkTypes = _postedDrinkTypeEntries.toList();
                    _updateDrinkType(targetDrinkTypes[index - 1].value, 'carousel');
                    _scrollToDrinkType(index);
                  },
                ),
                items: [
                  _timeline(null),
                  ..._postedDrinkTypeEntries
                    .map((entry) => _timeline(entry.value))
                    .toList()
                ],
              ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).accentColor,
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () {
                    _updateTimelineType(TimelineType.Mine);
                    _scrollToDrinkType(0);
                    if (widget.user != null) {
                      _carouselController.jumpToPage(0);
                    }
                  },
                  icon: Icon(
                    Icons.home,
                    size: 32,
                    color: _timelineType == TimelineType.Mine
                      ? Colors.white
                      : Theme.of(context).primaryColorLight,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () {
                    _updateTimelineType(TimelineType.All);
                    _scrollToDrinkType(0);
                    if (widget.user != null) {
                      _carouselController.jumpToPage(0);
                    }
                  },
                  icon: Icon(
                    Icons.people,
                    size: 32,
                    color: _timelineType == TimelineType.All
                      ? Colors.white
                      : Theme.of(context).primaryColorLight,
                  ),
                ),
              ),
              Container(
                width: 88,
                height: 40,
              ),
              Expanded(
                flex: 1,
                child: Container(height: 0),
              ),
              Expanded(
                flex: 1,
                child: widget.user == null
                  ? Container(height: 0)
                  : IconButton(
                    onPressed: () => Navigator.of(context).pushNamed('/setting'),
                    icon: Icon(
                      Icons.settings,
                      size: 32,
                      color: Theme.of(context).primaryColorLight,
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.user == null ? null : _movePostPage,
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(
          Icons.add,
          color: widget.user == null ? Theme.of(context).primaryColorLight : Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _timeline(DrinkType targetDrinkType) {
    final drinks = _getTargetDrinks(targetDrinkType);

    if (drinks == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (drinks.length == 0) {
      return Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _timelineType == TimelineType.Mine
            ? <Widget>[
              NormalText(
                'あなたのお酒が表示されます',
                bold: true,
              ),
              Padding(padding: EdgeInsets.only(bottom: 24)),
              NormalText(
                '飲んだお酒を投稿してみましょう',
                bold: true,
              ),
              Padding(padding: EdgeInsets.only(bottom: 24)),
              Icon(Icons.arrow_downward),
            ]
          : <Widget>[
              NormalText(
                'お酒が見つかりませんでした',
                bold: true,
              ),
            ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: DrinkGrid(drinks: drinks, updateDrink: _updateDrink),
    );
  }

  Widget _drinkTypeList() =>
    ListView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      children: <Widget>[
        ButtonTheme(
          minWidth: 80,
          child: FlatButton(
            textColor: _drinkType == null
                ? Colors.white
                : Colors.white38,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                NormalText(
                  '全て',
                  bold: _drinkType == null,
                ),
                Padding(padding: EdgeInsets.only(right: 4)),
                LabelText(
                  _getUploadCount(null).toString(),
                  size: 'small',
                  single: true,
                ),
              ],
            ),
            onPressed: () {
              _updateDrinkType(null, 'button');
              _carouselController.animateToPage(
                0,
                curve: Curves.easeOut,
                duration: Duration(milliseconds: 300),
              );
            },
          ),
        ),
        ..._postedDrinkTypeEntries.map((entry) {
          final index = entry.key;
          final userDrinkType = entry.value;

          return ButtonTheme(
            minWidth: 80,
            child: FlatButton(
              textColor: _drinkType == userDrinkType
                  ? Colors.white
                  : Colors.white38,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  NormalText(
                    userDrinkType.label,
                    bold: _drinkType == userDrinkType,
                  ),
                  Padding(padding: EdgeInsets.only(right: 4)),
                  LabelText(
                    _getUploadCount(userDrinkType).toString(),
                    size: 'small',
                    single: true,
                  ),
                ],
              ),
              onPressed: () {
                _updateDrinkType(userDrinkType, 'button');
                _carouselController.animateToPage(index + 1);
              },
            ),
          );
        }).toList()
      ],
    );

  Widget _orderMenu() =>
    PopupMenuButton(
      onSelected: _updateOrderType,
      icon: Icon(Icons.sort),
      itemBuilder: (BuildContext context) =>
        OrderType.values.map((orderType) =>
          PopupMenuItem(
            value: orderType,
            child: NormalText(
              orderType.label,
              bold: orderType == _orderType,
            ),
          )
        ).toList(),
    );

  Widget _signInContainer() =>
    Stack(
      children: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            NormalText(
              'お酒を投稿するには\nアカウント認証が必要です。',
              multiLine: true,
            ),
            Padding(padding: EdgeInsets.only(bottom: 32)),

            RaisedButton(
              onPressed: _checkSignIn,
              child: Text(
                'Googleで認証する',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              color: Theme.of(context).accentColor,
              textColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(padding: EdgeInsets.only(bottom: 32)),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SmallText(
                  '※',
                  multiLine: true,
                ),
                Padding(padding: EdgeInsets.only(right: 4)),
                SmallText(
                  'プライバシーポリシーに\n同意の上認証をしてください。',
                  multiLine: true,
                ),
              ],
            ),

            FlatButton(
              child: Text(
                'プライバシーポリシー',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              onPressed: () => launch('https://cellar.sesta.dev/policy'),
            ),
            Padding(padding: EdgeInsets.only(bottom: 80)),
          ]
        ),
        _loadingSignIn ? Container(
          padding: EdgeInsets.only(bottom: 80),
          color: Colors.black38,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ) : Container(),
      ],
    );
}
