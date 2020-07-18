import 'dart:async';

import 'package:cellar/domain/entities/drink.dart';
import 'package:cellar/repository/drink_repository.dart';
import 'package:cellar/repository/provider/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TimelineType {
  Mine,
  All,
}

Future<List<Drink>> getTimelineImageUrls(TimelineType timelineType, {
  DrinkType drinkType,
  String userId,
}) async {
  final List<String> whereKeys = [];
  final List<dynamic> whereEqualValues = [];

  List<DocumentSnapshot> rawData;

  switch (timelineType) {
    // TODO: userIdがなかったらthrowする
    case TimelineType.Mine:
      whereKeys.add('userId');
      whereEqualValues.add(userId);
      rawData = await getDocuments(
        'drinks',
        whereKeys: whereKeys,
        whereEqualValues: whereEqualValues,
        orderKey: 'postTimestamp',
        isDeskOrder: true,
      );
      break;
    case TimelineType.All:
      rawData = await DrinkRepository().getPublicDrinks(drinkType);
      break;
  }

  final drinks = rawData.map((data) => Drink(
    data['userId'],
    data['userName'],
    data['drinkName'],
    DrinkType.values[data['drinkTypeIndex']],
    SubDrinkType.values[data['subDrinkTypeIndex']],
    data['score'],
    data['memo'],
    data['price'],
    data['place'],
    DateTime.fromMicrosecondsSinceEpoch(data['postTimestamp'] * 1000),
    data['thumbImagePath'],
    data['imagePaths'].cast<String>(),
    data['firstImageWidth'],
    data['firstImageHeight'],
    drinkId: data.documentID,
  )).toList();

  await Future.forEach(drinks, (drink) async {
    await drink.init();
  });

  return drinks;
}
