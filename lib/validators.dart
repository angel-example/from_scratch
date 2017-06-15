import 'package:angel_validate/angel_validate.dart';

// We can use validators on both the client and server.
//
// Define validation schemas using the same `matcher` library used
// in `package:test`.
final Validator ITEM = new Validator({
  'name': isNonEmptyString,
  'email': [isEmail]
});

// Validators can be extended to apply specific rules in certain situations.
final Validator CREATE_ITEM = ITEM.extend({})
  ..requiredFields.addAll(['name', 'email']);
