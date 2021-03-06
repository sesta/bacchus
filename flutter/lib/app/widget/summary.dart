import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:lottie/lottie.dart';

import 'package:cellar/domain/entity/entities.dart';
import 'package:cellar/repository/drink_repository.dart';

class Summary extends StatefulWidget {
  Summary({
    Key key,
    @required this.user,
  }) : super(key: key);

  final User user;

  @override
  _SummaryState createState() => _SummaryState();
}

class _SummaryState extends State<Summary> {
  List<DrinkType> _drinkTypes;
  List<Drink> _drinks = [];
  Map<DrinkType, double> _scoreAverageMap= {};
  Map<DateTime, List<Drink>> _postDateTimeMap = {};

  CalendarController _calendarController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController();
    _drinkTypes = widget.user.drinkTypesByMany
      .where((drinkType) => widget.user.uploadCounts[drinkType] > 0)
      .toList();
    _calc();
  }

  Future<void> _calc() async {
    _drinks = await DrinkRepository().getUserAllDrinks(widget.user.userId);

    _drinks.forEach((drink) {
      if (_scoreAverageMap[drink.drinkType] == null) {
        _scoreAverageMap[drink.drinkType] = 0;
      }
      _scoreAverageMap[drink.drinkType] += drink.score;

      if (_postDateTimeMap[drink.drinkDateTime] == null) {
        _postDateTimeMap[drink.drinkDateTime] = [];
      }
      _postDateTimeMap[drink.drinkDateTime].add(drink);
    });

    _scoreAverageMap.forEach((key, value) {
      _scoreAverageMap[key] /= widget.user.uploadCounts[key];
    });

    setState(() {
      _loading = false;
    });
  }

  List<charts.Series<DrinkType, String>> get _postCountRateData =>
    [
      charts.Series<DrinkType, String>(
        id: 'Drinks',
        domainFn: (drinkType, _) => drinkType.label,
        measureFn: (drinkType, _) => widget.user.uploadCounts[drinkType],
        data: _drinkTypes,
        labelAccessorFn: (drinkType, _) {
          final rate = (widget.user.uploadCounts[drinkType]/widget.user.uploadCount*100).toStringAsFixed(0);
          return '$rate%\n${drinkType.label}';
        },
        colorFn: (drinkType, _) => charts.ColorUtil.fromDartColor(
          Theme.of(context).primaryColorDark,
        ),
        outsideLabelStyleAccessorFn: (drinkType, _) => charts.TextStyleSpec(
          color: charts.MaterialPalette.white
        ),
      )
    ];

  List<charts.Series<DrinkType, String>> get _scoreAverageData =>
    [
      charts.Series<DrinkType, String>(
        id: 'Drinks',
        domainFn: (drinkType, _) => '${_scoreAverageMap[drinkType].toStringAsFixed(1)}\n${drinkType.label}',
        measureFn: (drinkType, _) => _scoreAverageMap[drinkType],
        data: _drinkTypes,
        colorFn: (drinkType, _) => charts.ColorUtil.fromDartColor(
          Theme.of(context).primaryColorDark,
        ),
      )
    ];

  @override
  Widget build(BuildContext context) {
    if (widget.user.uploadCount == 0) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Text(
            '飲んだお酒を投稿してみましょう',
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.topLeft,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).padding.top + 32,
            horizontal: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '投稿の割合',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Padding(padding: EdgeInsets.only(bottom: 16)),
              _postRate,
              Padding(padding: EdgeInsets.only(bottom: 32)),

              Text(
                'スコアの平均',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Padding(padding: EdgeInsets.only(bottom: 8)),
              _scoreAverage,
              Padding(padding: EdgeInsets.only(bottom: 48)),

              Text(
                '投稿した日',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Padding(padding: EdgeInsets.only(bottom: 8)),
              _postCalendar,
              Padding(padding: EdgeInsets.only(bottom: 64)),
            ],
          )
        ),
      ),
    );
  }

  Widget get _postCalendar =>
    TableCalendar(
      events: _postDateTimeMap,
      calendarController: _calendarController,
      locale: 'ja_JP',
      availableCalendarFormats: {
        CalendarFormat.month: 'Month'
      },
      endDay: DateTime.now(),
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarStyle: CalendarStyle(
        selectedColor: Theme.of(context).scaffoldBackgroundColor,
        todayColor: Theme.of(context).scaffoldBackgroundColor,
        weekendStyle: TextStyle().copyWith(color: Colors.orangeAccent),
        outsideDaysVisible: false,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle().copyWith(color: Colors.grey),
        weekendStyle: TextStyle().copyWith(color: Colors.orangeAccent[100]),
      ),
      headerStyle: HeaderStyle(
        centerHeaderTitle: true,
        formatButtonVisible: false,
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Colors.white,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Colors.white,
        ),
      ),
      builders: CalendarBuilders(
        markersBuilder: (context, date, events, holidays) => [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              height: 4,
              width: 100,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
      onDaySelected: (_, events) {
        if (events.length == 0) {
          return;
        }

        Navigator.of(context).pushNamed('/drink', arguments: events[0]);
      },
    );

  Widget get _postRate =>
    Container(
      height: 280,
      child: _loading
        ? Center(
            child: Lottie.asset(
              'assets/lottie/loading.json',
              width: 80,
              height: 80,
            ),
          )
        : charts.PieChart(
            _postCountRateData,
            animate: true,
            defaultRenderer: charts.ArcRendererConfig(
              arcRendererDecorators: [
                charts.ArcLabelDecorator()
              ],
              strokeWidthPx: 1,
            ),
          ),
    );

  Widget get _scoreAverage =>
    Container(
      height: 20.0 + 48 * _drinkTypes.length,
      child: _loading
        ? Center(
            child: Lottie.asset(
              'assets/lottie/loading.json',
              width: 80,
              height: 80,
            ),
          )
        : charts.BarChart(
            _scoreAverageData,
            animate: true,
            vertical: false,
            domainAxis: charts.OrdinalAxisSpec(
              renderSpec: charts.SmallTickRendererSpec(
                labelStyle: charts.TextStyleSpec(
                  color: charts.MaterialPalette.white
                ),
              ),
            ),
            primaryMeasureAxis: charts.NumericAxisSpec(
              tickProviderSpec: charts.BasicNumericTickProviderSpec(
                desiredTickCount: 6
              ),
              renderSpec: charts.GridlineRendererSpec(
                labelStyle: charts.TextStyleSpec(
                  color: charts.MaterialPalette.white
                ),
              ),
            ),
          ),
    );
}
