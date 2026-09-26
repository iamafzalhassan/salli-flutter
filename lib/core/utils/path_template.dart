extension PathTemplate on String {
  String withId(String id) => replaceFirst(':id', Uri.encodeComponent(id));
}
