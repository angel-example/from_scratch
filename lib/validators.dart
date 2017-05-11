import 'package:angel_validate/angel_validate.dart';

final Validator ITEM = new Validator({
  'name': [isString, isNotEmpty],
  'email': [isEmail]
});

final Validator CREATE_ITEM = ITEM.extend({})
  ..requiredFields.addAll(['name', 'email']);
