class ChatModel {
  final String id;
  final String firstname;
  final String lastname;
  final String group;
  final String? parent;
  final String email;
  final String picture;
  final String content;

  ChatModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.group,
     this.parent,
    required this.email,
    required this.picture,
    required this.content,
  });



  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json["_id"] as String,
      content: json["content"] as String,
      group: json["group"] as String,
      parent: json["parent"] as String?, // Use String? if 'parent' can be null
      firstname: json["firstname"] as String,
      lastname: json["lastname"] as String,
      email: json["email"] as String,
      picture: json["picture"] as String,
    );
  }


}


