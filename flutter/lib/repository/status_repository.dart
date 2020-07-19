import 'dart:async';
import 'package:cellar/domain/entities/drink.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cellar/conf.dart';
import 'package:cellar/domain/entities/status.dart';
import 'package:cellar/repository/provider/firestore.dart';

class StatusRepository extends DB {
  // TODO: environmentを自分で持つ

  Future<Status> getStatus(
    String environment,
  ) async {
    final statusRef = db.collection(STATUS_COLLECTION_NAME)
      .document(environment);
    final drinkTypesData = await statusRef.collection('drinkTypes')
      .getDocuments();

    return _toEntity(drinkTypesData.documents);
  }

  Future<void> incrementUploadCount(
    String environment,
    DrinkType drinkType,
  ) async {
    await db.collection(STATUS_COLLECTION_NAME)
      .document(environment)
      .collection('drinkTypes')
      .document(drinkType.index.toString())
      .updateData({
        'uploadCount': FieldValue.increment(1),
      });
  }

  Future<void> decrementUploadCount(
    String environment,
    DrinkType drinkType,
  ) async {
    await db.collection(STATUS_COLLECTION_NAME)
      .document(environment)
      .collection('drinkTypes')
      .document(drinkType.index.toString())
      .updateData({
        'uploadCount': FieldValue.increment(-1),
      });
  }

  Status _toEntity(
    List<DocumentSnapshot> drinkTypesData,
  ) {
    drinkTypesData.sort((DocumentSnapshot dataA, DocumentSnapshot dataB) {
      final idA = int.parse(dataA.documentID);
      final idB = int.parse(dataB.documentID);
      return idA.compareTo(idB);
    });
    final drinkTypeUploadCounts = drinkTypesData.map((data) {
      return data['uploadCount'];
    }).toList().cast<int>();

    return Status(
      drinkTypeUploadCounts,
    );
  }
}
