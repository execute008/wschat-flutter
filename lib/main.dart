import 'dart:convert';

import 'package:color_parser/color_parser.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'WS Chat';
    return const MaterialApp(
      title: title,
      home: MyHomePage(
        title: title,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:8080'),
  );

  String? name;
  List<Message> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder(
          stream: _channel.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var data = jsonDecode(snapshot.data);
              if (data['uname'] != null) {
                name = data['uname'];
              }
              if (data['name'] != null &&
                  data['msg'] != null &&
                  data['color'] != null &&
                  data['time'] != null) {
                Color? color = ColorParser.hex(data['color']).getColor();
                messages.add(
                  Message(
                    sender: data['name'],
                    msg: data['msg'],
                    color: color ?? const Color(0xFF000000),
                    time: DateTime.fromMillisecondsSinceEpoch(data['time']),
                  ),
                );
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [...(name == null ? buildLogin() : buildChat())],
            );
          }),
    );
  }

  void _sendMessage(bool login) {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(login
          ? jsonEncode({"cmd": "login", "name": _controller.text})
          : jsonEncode({"cmd": "msg", "msg": _controller.text}));
    }
    _controller.text = "";
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  List<Widget> buildChat() {
    return [
      buildMessageList(),
      buildInputArea(context, false),
    ];
  }

  List<Widget> buildLogin() {
    return [
      buildInputArea(context, true),
    ];
  }

  Widget buildInputArea(BuildContext context, bool login) {
    return Row(
      children: <Widget>[
        Expanded(
          child: login
              ? TextField(
                  maxLength: 20,
                  minLines: 1,
                  maxLines: 1,
                  controller: _controller,
                  decoration:
                      const InputDecoration(labelText: "Enter your Name"),
                )
              : TextField(
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 5,
                  controller: _controller,
                  decoration: const InputDecoration(labelText: "Enter Message"),
                ),
        ),
        IconButton(
          onPressed: () => _sendMessage(login),
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }

  Widget buildMessageList() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    messages[index].sender,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: messages[index].color,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          messages[index].msg,
                          style: TextStyle(
                              color: getTextColorForBackground(
                            messages[index].color,
                          )),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(DateFormat.Hm().format(messages[index].time))
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color getTextColorForBackground(Color backgroundColor) {
  if (ThemeData.estimateBrightnessForColor(backgroundColor) ==
      Brightness.dark) {
    return Colors.white;
  }

  return Colors.black;
}

class Message {
  String sender;
  String msg;
  Color color;
  DateTime time;

  Message({
    required this.sender,
    required this.msg,
    required this.color,
    required this.time,
  });
}
