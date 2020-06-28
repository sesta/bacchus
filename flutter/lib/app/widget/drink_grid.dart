import 'package:flutter/material.dart';

import 'package:bacchus/domain/entities/drink.dart';

class DrinkGrid extends StatelessWidget {
  final List<Drink> drinks;
  DrinkGrid({this.drinks});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      padding: EdgeInsets.all(16),
      childAspectRatio: 1,
      children: drinks.map<Widget>((drink) {
        return Hero(
          tag: drink.thumbImageUrl,
          child: GestureDetector(
            child: GridItem(name: drink.name, imageUrl: drink.thumbImageUrl),
            onTap: () => Navigator.of(context).pushNamed('/drink', arguments: drink),
          ),
        );
      }).toList(),
    );
  }
}

class GridItem extends StatelessWidget {
  GridItem({
    Key key,
    this.name,
    this.imageUrl,
  });
  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GridTile(
      footer: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
        clipBehavior: Clip.antiAlias,
        child: GridTileBar(
          backgroundColor: Colors.black45,
          title: Text(name)
        ),
      ),
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAlias,
        child: Image(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
