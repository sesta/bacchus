import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:bacchus/domain/entities/user.dart';
import 'package:bacchus/domain/models/post.dart';

class PostPage extends StatefulWidget {
  PostPage({Key key, this.user}) : super(key: key);

  final User user;

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  void _getImageList() async {
    List<Asset> resultList;
    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
      );
    } catch (e) {
      return ;
    }

    if (resultList == null || resultList.length == 0) {
      return ;
    }

    await post(widget.user.id, resultList);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('酒の投稿'),
      ),
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  onPressed: _getImageList,
                  child: Text('投稿する'),
                ),
              ]
          )
      )
    );
  }
}