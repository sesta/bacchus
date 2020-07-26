import 'dart:async';
import 'package:cellar/domain/entities/drink.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cellar/conf.dart';
import 'package:cellar/domain/entities/user.dart';
import 'package:cellar/repository/provider/firestore.dart';

class UserRepository extends DB {
  Future<User> getUser(
      String userId,
  ) async {
    final snapshot = await db.collection(USER_COLLECTION_NAME)
      .document(userId)
      .get();

    if (snapshot.data == null) {
      return null;
    }

    return _toEntity(userId, snapshot);
  }

  Future<void> createUser(User user) async {
    await db.collection(USER_COLLECTION_NAME)
      .document(user.userId)
      .setData({
        'userName': user.userName,
        'uploadCounts': {},
      });
  }

  Future<void> updateUserName(
    String userId,
    String userName,
  ) async {
    await db.collection(USER_COLLECTION_NAME)
      .document(userId)
      .updateData({ 'userName': userName });
  }

  Future<void> updateUserUploadCount(
    String userId,
    Map<DrinkType, int> uploadCounts,
  ) async {
    Map<String, int> counts = {};
    DrinkType.values.forEach((drinkType) {
      if (uploadCounts[drinkType] > 0) {
        counts[drinkType.toString()] = uploadCounts[drinkType];
      }
    });

    await db.collection(USER_COLLECTION_NAME)
      .document(userId)
      .updateData({ 'uploadCounts': counts });
  }

  Future<User> _toEntity(
    String userId,
    DocumentSnapshot rawData,
  ) async {
    Map<DrinkType, int> counts = {};
    DrinkType.values.forEach((drinkType) {
      // 新しいDrinkTypeが追加される可能性があるので、存在しない場合を考慮する
      counts[drinkType] = rawData['uploadCounts'][drinkType.toString()] != null
        ? rawData['uploadCounts'][drinkType.toString()]
        : 0;
    });

    return User(
      userId,
      rawData['userName'],
      uploadCounts: counts,
    );
  }
}