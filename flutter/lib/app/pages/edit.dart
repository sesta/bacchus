import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:cellar/domain/entities/status.dart';
import 'package:cellar/domain/entities/drink.dart';
import 'package:cellar/domain/entities/user.dart';
import 'package:cellar/repository/analytics_repository.dart';

import 'package:cellar/app/widget/drink_form.dart';
import 'package:cellar/app/widget/atoms/normal_text.dart';

class EditPage extends StatefulWidget {
  EditPage({
    Key key,
    this.status,
    this.user,
    this.drink,
  }) : super(key: key);

  final Status status;
  final User user;
  final Drink drink;

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  DateTime _drinkDateTime = DateTime.now(); // TODO: ちゃんとする
  DrinkType _drinkType;
  SubDrinkType _subDrinkType = SubDrinkType.Empty;
  int _score = 3;
  bool _uploading = false;

  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  final _priceController = TextEditingController();
  final _placeController = TextEditingController();

  @override
  initState() {
    super.initState();

    _nameController.text = widget.drink.drinkName;
    _memoController.text = widget.drink.memo;
    _placeController.text = widget.drink.place;
    if (widget.drink.price > 0) {
      _priceController.text = widget.drink.price.toString();
    }

    _nameController.addListener(() => setState(() {}));

    setState(() {
      _drinkType = widget.drink.drinkType;
      _subDrinkType = widget.drink.subDrinkType;
      _score = widget.drink.score;
    });
  }

  get _disablePost {
    return _nameController.text == ''
      || _drinkType == null;
  }

  _updateDrinkDateTime(DateTime drinkDateTime) {
    setState(() {
      _drinkDateTime = drinkDateTime;
    });
  }

  _updateDrinkType(DrinkType drinkType) {
    setState(() {
      _drinkType = drinkType;
      _subDrinkType = SubDrinkType.Empty;
    });
  }

  _updateSubDrinkType(SubDrinkType subDrinkType) {
    setState(() {
      _subDrinkType = subDrinkType;
    });
  }

  _updateScore(int score) {
    setState(() {
      _score = score;
    });
  }

  Future<void> _updateDrink() async {
    if (_disablePost) {
      return;
    }

    setState(() {
      _uploading = true;
    });

    final oldDrinkType = widget.drink.drinkType;

    await widget.drink.update(
      _nameController.text,
      _drinkType,
      _subDrinkType,
      _score,
      _memoController.text,
      _priceController.text == '' ? 0 : int.parse(_priceController.text),
      _placeController.text,
    );
    if (_drinkType != oldDrinkType) {
      await widget.user.moveUploadCount(oldDrinkType, _drinkType);
      await widget.status.moveUploadCount(oldDrinkType, _drinkType);
    }

    AnalyticsRepository().sendEvent(
      EventType.EditDrink,
      { 'drinkId': widget.drink.drinkId },
    );
    Navigator.of(context).pop(false);
  }

  Future<void> _confirmDelete() async {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            title: NormalText(
              "本当に削除してよろしいですか？",
              bold: true,
            ),
            content: NormalText(
              '削除した投稿は復元できません。',
              multiLine: true,
            ),
            actions: <Widget>[
              // ボタン領域
              FlatButton(
                child: Text(
                  'やめる',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              FlatButton(
                child: Text(
                  '削除する',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _delete();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _delete() async {
    setState(() {
      _uploading = true;
    });

    await widget.drink.delete();
    await widget.user.decrementUploadCount(_drinkType);
    await widget.status.decrementUploadCount(_drinkType);

    AnalyticsRepository().sendEvent(
      EventType.DeleteDrink,
      { 'drinkId': widget.drink.drinkId },
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '編集',
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(padding: EdgeInsets.only(bottom: 24)),
                DrinkForm(
                  user: widget.user,
                  drinkDateTime: _drinkDateTime,
                  nameController: _nameController,
                  priceController: _priceController,
                  placeController: _placeController,
                  memoController: _memoController,
                  score: _score,
                  drinkType: _drinkType,
                  subDrinkType: _subDrinkType,
                  updateDrinkDateTime: _updateDrinkDateTime,
                  updateDrinkType: _updateDrinkType,
                  updateSubDrinkType: _updateSubDrinkType,
                  updateScore: _updateScore,
                ),
                Padding(padding: EdgeInsets.only(bottom: 64)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      onPressed: _confirmDelete,
                      child: NormalText(
                        '削除する',
                        bold: true,
                      ),
                      color: Colors.redAccent,
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(right: 32)),
                    RaisedButton(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      onPressed: _disablePost ? null : _updateDrink,
                      child: NormalText(
                        '更新する',
                        bold: true,
                      ),
                      color: Theme.of(context).accentColor,
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _uploading ? Container(
            color: Colors.black38,
            alignment: Alignment.center,
            child: Lottie.asset(
              'assets/lottie/loading.json',
              width: 80,
              height: 80,
            ),
          ) : Container(),
        ],
      ),
    );
  }
}
