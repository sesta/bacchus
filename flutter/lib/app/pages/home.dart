import 'dart:async';
import 'package:flutter/material.dart';

import 'package:cellar/domain/entities/status.dart';
import 'package:cellar/domain/entities/user.dart';
import 'package:cellar/domain/entities/drink.dart';
import 'package:cellar/domain/models/timeline.dart';

import 'package:cellar/app/widget/drink_grid.dart';
import 'package:cellar/app/widget/atoms/label_test.dart';
import 'package:cellar/app/widget/atoms/main_text.dart';
import 'package:cellar/app/widget/atoms/normal_text.dart';

class HomePage extends StatefulWidget {
  HomePage({
    Key key,
    this.user,
    this.status,
  }) : super(key: key);

  final Status status;
  final User user;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Drink> drinks = [];
  TimelineType timelineType = TimelineType.Mine;
  DrinkType drinkType;
  bool loading = true;

  @override
  initState() {
    super.initState();

    _updateTimeline();
  }

  _movePostPage() async {
    final isPosted = await Navigator.of(context).pushNamed('/post');

    if (isPosted != null) {
      _updateTimeline();
    }
  }

  Future<void> _updateTimeline() async {
    setState(() {
      this.loading = true;
      this.drinks = [];
    });

    final drinks = await getTimelineImageUrls(
      timelineType,
      drinkType: drinkType,
      userId: widget.user.userId,
    );

    setState(() {
      this.drinks = drinks;
      this.loading = false;
    });
  }

  _updateTimelineType(TimelineType timelineType) {
    if (this.timelineType == timelineType) {
      return;
    }

    setState(() {
      this.timelineType = timelineType;
      this.drinkType = null;
    });

    _updateTimeline();
  }

  _updateDrinkType(DrinkType drinkType) {
    if (this.drinkType == drinkType) {
      return;
    }

    setState(() {
      this.drinkType = drinkType;
    });

    _updateTimeline();
  }

  Future<void> _refresh() async {
    await _updateTimeline();
  }

  int getUploadCount(DrinkType drinkType) {
    if (drinkType == null) {
      switch(timelineType) {
        case TimelineType.All:
          return widget.status.uploadCount;
        case TimelineType.Mine:
          return widget.user.uploadCount;
      }
    }

    switch(timelineType) {
      case TimelineType.All:
        return widget.status.drinkTypeUploadCounts[drinkType.index];
      case TimelineType.Mine:
        return widget.user.drinkTypeUploadCounts[drinkType.index];
    }

    throw 'timelineTypeの考慮漏れです';
  }

  _updateDrink(int index, bool isDelete) {
    if (isDelete) {
      setState(() {
        this.drinks.removeAt(index);
      });
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
            ),
            child: Container(
              alignment: Alignment.topLeft,
              child: Text(
                'Cellar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 16)),
          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                ButtonTheme(
                  minWidth: 40,
                  child: FlatButton(
                    textColor: drinkType == null
                      ? Colors.white
                      : Colors.white38,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        NormalText(
                          '全て',
                          bold: drinkType == null,
                        ),
                        Padding(padding: EdgeInsets.only(right: 4)),
                        LabelText(
                          getUploadCount(null).toString(),
                          size: 'small',
                          single: true,
                        ),
                      ],
                    ),
                    onPressed: () => _updateDrinkType(null),
                  ),
                ),
                ...widget.user.drinkTypesByMany.map((userDrinkType) {
                  final count = getUploadCount(userDrinkType);
                  if (count == 0) {
                    return Container();
                  }

                  return ButtonTheme(
                    minWidth: 40,
                    child: FlatButton(
                      textColor: drinkType == userDrinkType
                          ? Colors.white
                          : Colors.white38,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: <Widget>[
                          NormalText(
                            userDrinkType.label,
                            bold: drinkType == userDrinkType,
                          ),
                          Padding(padding: EdgeInsets.only(right: 4)),
                          LabelText(
                            count.toString(),
                            size: 'small',
                            single: true,
                          ),
                        ],
                      ),
                      onPressed: () => _updateDrinkType(userDrinkType),
                    ),
                  );
                }).toList()
              ],
            ),
          ),
          Expanded(
            child: loading
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                ],
              )
              : RefreshIndicator(
                onRefresh: _refresh,
                child: drinks.length == 0
                  ? SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 200,
                        bottom: 100,
                      ),
                      child: Column(
                        children: <Widget>[
                          NormalText('投稿したお酒が表示されます'),
                          Padding(padding: EdgeInsets.only(bottom: 140)),
                          MainText('投稿はこちら'),
                          Padding(padding: EdgeInsets.only(bottom: 16)),
                          Icon(Icons.arrow_downward),
                        ],
                      ),
                    ),
                  )
                  : DrinkGrid(drinks: drinks, updateDrink: _updateDrink),
              ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).accentColor,
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () => _updateTimelineType(TimelineType.Mine),
                  icon: Icon(
                    Icons.home,
                    size: 32,
                    color: timelineType == TimelineType.Mine
                      ? Colors.white
                      : Theme.of(context).primaryColorLight,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () => _updateTimelineType(TimelineType.All),
                  icon: Icon(
                    Icons.people,
                    size: 32,
                    color: timelineType == TimelineType.All
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
                child: IconButton(
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
        onPressed: _movePostPage,
        tooltip: 'Increment',
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
