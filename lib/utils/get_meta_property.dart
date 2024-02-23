import 'package:html/dom.dart';

String? getMetaProperty(
  Document document, {
  String tag = 'meta',
  String attribute = 'property',
  String? property,
  String key = 'content',
}) {
  return document
      .getElementsByTagName(tag)
      .cast<Element?>()
      .firstWhere((element) => element?.attributes[attribute] == property,
          orElse: () => null)
      ?.attributes
      [key];
}