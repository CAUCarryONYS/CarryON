import "dart:async";
import "../ui.dart";
import "../models/chatModel.dart";
import "../tts.dart";
import "../widgets/errorDialog.dart";
import "../models/chatUserModel.dart";
import "package:http/http.dart" as http;
import "dart:convert";
import "../models/chatroomModel.dart";

class ServerConnect {
  static const String url = 'http://copytixe.iptime.org:8085/';
  late String myName;
  late String myPassword;
  late String id;
  String? profileImage;
  late int primaryKey;
  late String sessionID;

  Future<bool> login(String id, String password) async {
    this.id = id;
    myPassword = password;
    LoginAPI login = LoginAPI(id, password);
    await login.get();
    try {
      if (!login.isLogin) {
        throw Exception(login.data['isLogin']);
      }
      myName = login.name;
      primaryKey = login.primaryKey;
      sessionID = login.getSessionID()!;
      profileImage = login.profileImage;
    } catch (e) {
      rethrow;
    }
    return true;
  }

  Future<void> logout() async {
    LogoutAPI logout = LogoutAPI(sessionID);
    await logout.get();
  }

  Future<bool> addFriends(String friendId) async {
    AddFriendsAPI addFriends = AddFriendsAPI(sessionID, friendId);
    await addFriends.get();
    return addFriends.isSuccess;
  }

  Future<List<ChatUsers>> getFriendList() async {
    FriendListAPI fl = FriendListAPI(sessionID);
    List<ChatUsers> ret = List.empty(growable: true);
    await fl.get();
    if (!fl.isSuccess) {
      throw fl.response.statusCode;
    }
    for (var element in fl.data) {
      ret.add(ChatUsers(
        element["name"],
        element["id"],
        element["chatRoomId"],
        element["profileImage"],
      ));
    }
    return ret;
  }

  Future<bool> deleteFriend(String friendId) async {
    DeleteFriendAPI deleteFriend = DeleteFriendAPI(sessionID, friendId);
    await deleteFriend.get();
    return deleteFriend.isSuccess;
  }

  Future<List<Chatroom>> getChatroomList() async {
    ChatroomListAPI cl = ChatroomListAPI(sessionID);
    List<Chatroom> chatroomList = List.empty(growable: true);
    await cl.get();
    if (!cl.isSuccess) throw cl.response.statusCode;
    for (var element in cl.data) {
      Chatroom chatroom = Chatroom(
        chatRoomId: element['chatRoomId'],
        chatroomName: element['chatRoomName'],
        participantId: List<int>.from(element['participantIds']),
        participantName: List<String>.from(element['participantNames']),
        latestMessage: element['latestMessage'],
        latestMessageSenderId: element['latestMessageSenderId'],
        lastMessageSenderName: element['lastMessageSenderName'],
        lastMessageTimestamp: element['latestMessageTimestamp'],
        imageStr: List<String>.from(element["participantProfileImages"]),
      );
      chatroomList.add(chatroom);
    }
    return chatroomList;
  }

  Future<List<Message>> getMessageList(int chatroomId, TTS chatTts) async {
    ChatListAPI cl = ChatListAPI(sessionID, chatroomId);
    List<Message> messageList = List.empty(growable: true);

    await cl.get();
    if (!cl.isSuccess) throw cl.response.statusCode;
    for (var element in cl.data) {
      Message message = Message(
        chatTts: chatTts,
        message: element['message'],
        senderId: element['senderId'],
        senderName: element['senderName'],
        timestamp: element['timestamp'],
        profileImage: element['profileImage'],
      );
      messageList.add(message);
    }

    return messageList;
  }
  Future<bool> updateUserInfo(String? name, String? password, String? profileImage) async{
    UserUpdateAPI userUpdateAPI = UserUpdateAPI(sessionID, name: name??myName, password: password??myPassword, profileImage: profileImage);
    await userUpdateAPI.get();
    if(!userUpdateAPI.isSuccess) return false;
    return true;
  }
}

abstract class ServerPostAPI extends ServerAPI {
  abstract final String body;

  @override
  Future<void> _getResponse() async {
    response = await http.post(Uri.parse(url), headers: headers, body: body);
    print(utf8.decode(response.bodyBytes));
  }
}

abstract class ServerAPI {
  late String url;
  late String sessionID;
  late http.Response response;
  late dynamic data;

  Map<String, String> get headers =>
      {'Content-Type': 'application/json', 'Cookie': 'JSESSIONID=$sessionID'};

  Future<void> _getResponse() async {
    response = await http.get(Uri.parse(url), headers: headers);
    print(utf8.decode(response.bodyBytes));
  }

  Future<void> get() async {
    await _getResponse();
    try {
      data = await json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print(e.toString());
    }
  }

  bool get isSuccess {
    try {
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class RegistrationAPI extends ServerPostAPI {
  String name;
  @override
  String id;
  String password;
  String? profileImage;
  @override
  String primaryKey = "";
  @override
  Map<String, String> get headers => {'Content-Type': 'application/json'};

  RegistrationAPI(this.name, this.id, this.password, this.profileImage);

  @override
  String get url => "${ServerConnect.url}registration";
  @override
  String get body => json.encode({
    'name': name,
    'loginId': id,
    'password': password,
    'profileImage': profileImage ?? "",
  });
}

class LoginAPI extends ServerPostAPI {
  final String id;
  final String password;

  LoginAPI(this.id, this.password) {
    url = "${ServerConnect.url}auth/login";
    sessionID = "";
  }

  @override
  String get body => json.encode({
    "loginId": id,
    "password": password,
  });

  String? getSessionID() {
    var str = response.headers['set-cookie'];
    str = str?.replaceAll("JSESSIONID=", "");
    str = str?.substring(0, str.indexOf(";"));
    return str;
  }

  String get name => data['userInfo'][0]['name'];
  int get primaryKey => int.parse(data['userInfo'][0]['id']);
  String get profileImage => data['userInfo'][0]['profileImage'];
  bool get isLogin => data['isLogin'] == 'True';
}

class LogoutAPI extends ServerPostAPI {
  final String sessionID;

  LogoutAPI(this.sessionID) {
    url = "${ServerConnect.url}auth/logout";
  }

  @override
  String get body => "";
}

class AddFriendsAPI extends ServerPostAPI {
  final String friendId;

  AddFriendsAPI(String sessionID, this.friendId) {
    this.sessionID = sessionID;
    url = "${ServerConnect.url}api/friends";
  }

  @override
  String get body => json.encode({
    "friendLoginId": friendId,
  });
}

class FriendListAPI extends ServerAPI {
  FriendListAPI(String sessionID) {
    this.sessionID = sessionID;
    url = "${ServerConnect.url}api/friends";
  }
}

class DeleteFriendAPI extends ServerAPI {
  final String friendId;

  DeleteFriendAPI(String sessionID, this.friendId) {
    this.sessionID = sessionID;
    url = "${ServerConnect.url}api/friends/$friendId";
  }

  @override
  Future<void> _getResponse() async {
    response = await http.delete(Uri.parse(url), headers: headers);
  }
}

class ChatroomListAPI extends ServerAPI {
  ChatroomListAPI(String sessionID) {
    this.sessionID = sessionID;
    url = "${ServerConnect.url}chat/chatRooms";
  }
}

class ChatListAPI extends ServerAPI {
  ChatListAPI(String sessionID, int chatroomId) {
    this.sessionID = sessionID;
    url = "${ServerConnect.url}chat/messages/$chatroomId";
  }
}
class UserUpdateAPI extends ServerPostAPI{
  String name, password;
  String? profileImage;

  UserUpdateAPI(String sessionID,{required this.name, required this. password, this.profileImage}){
    this.sessionID = sessionID;
    url = "${ServerConnect.url}user/update";
  }

  @override
  String get body => json.encode({
    "name": name,
    "password": password,
    "profileImage": profileImage??""
  });

}