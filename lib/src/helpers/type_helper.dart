bool isDynamicType(String type) {
  type = type.trim();
  if (type == 'dynamic' || type == 'dynamic?') {
    return true;
  }

  return false;
}

bool isNullableType(String type) {
  type = type.trim();
  if (isDynamicType(type)) {
    return true;
  }

  return type.endsWith('?');
}

String nullableType(String type) {
  type = type.trim();
  if (isDynamicType(type)) {
    return type;
  }

  if (type.endsWith('?')) {
    return type;
  }

  return '$type?';
}
