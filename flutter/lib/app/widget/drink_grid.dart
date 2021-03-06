import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

import 'package:cellar/conf.dart';
import 'package:cellar/domain/entity/entities.dart';

class DrinkGrid extends StatelessWidget {
  DrinkGrid({
    @required this.drinks,
    @required this.addDrinks,
  });
  final List<Drink> drinks;
  final addDrinks;

  ScrollController _scrollController;

  _pop(BuildContext context, int index, Drink drink) async {
    final isDelete = await Navigator.of(context).pushNamed('/drink', arguments: drink);

    if (isDelete) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  _finishScroll() {
    final scrollThreshold = _scrollController.position.maxScrollExtent - 100;
    if (_scrollController.position.pixels < scrollThreshold) {
      return;
    }

    addDrinks();
  }

  @override
  Widget build(BuildContext context) {
    if (_scrollController == null) {
      _scrollController = ScrollController();
      _scrollController.addListener(_finishScroll);
    }

    final List<Widget> drinkWidgets = [];
    drinks.asMap().forEach((index, drink) {
      drinkWidgets.add(GestureDetector(
        child: GridItem(drink: drink),
        onTap: () => _pop(context, index, drink),
      ));
    });

    return GridView.count(
      controller: _scrollController,
      physics: AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: EdgeInsets.only(
        top: 48,
        left: 16,
        right: 16,
        bottom: 200,
      ),
      childAspectRatio: IMAGE_ASPECT_RATIO,
      children: drinkWidgets,
    );
  }
}

class GridItem extends StatefulWidget {
  GridItem({
    Key key,
    this.drink,
  }) : super(key: key);

  final Drink drink;

  @override
  _GridItemState createState() => _GridItemState();
}

class _GridItemState extends State<GridItem> with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  @override
  initState() {
    super.initState();

    final loaded = widget.drink.thumbImageUrl != null;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: loaded ? 0 : 500),
    );
    if (loaded) {
      _animationController.forward();
      return;
    }

    widget.drink.init().then((_) async {
       setState(() {});
       // サムネぐらいは読み込めてることを信じて0.3秒後に表示
       await Future.delayed(Duration(milliseconds: 300));

       // 表示しようと思ったら別のページになってたりするので、念のためチェック
       if (!this.mounted) {
         return;
       }

       await _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeScaleTransition(
      animation: _animationController,
      child: GridTile(
        footer: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: Colors.black38,
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.drink.drinkName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Padding(padding: EdgeInsets.only(bottom: 4)),
                Row(
                  children: List.generate(5, (i)=> i).map<Widget>((index) =>
                      Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          index < widget.drink.score ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.orangeAccent,
                        ),
                      )
                  ).toList(),
                ),
              ],
            ),
          ),
        ),
        child: Material(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          clipBehavior: Clip.antiAlias,
          child: widget.drink.thumbImageUrl == null
            ? Container()
            : Image(
              image: NetworkImage(
                widget.drink.thumbImageUrl,
              ),
              fit: BoxFit.cover,
            ),
        ),
      ),
    );
  }
}
