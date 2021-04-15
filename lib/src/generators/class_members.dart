// @dart = 2.10
part of '../../generators.dart';

class ClassMembers {
  final Map<String, Field> constants = {};

  final Map<String, Field> fields = {};

  final Map<String, Method> methods = {};

  Field addField(String name, Field field, bool constant) {
    if (constants.containsKey(name) || fields.containsKey(name)) {
      throw StateError('Field already defined: $name');
    }

    var members = fields;
    if (constant) {
      members = constants;
    }

    members[name] = field;
    return field;
  }

  Method addMethod(String name, Method method) {
    if (methods.containsKey(name)) {
      throw StateError('Method already defined: $name');
    }

    methods[name] = method;
    return method;
  }
}
