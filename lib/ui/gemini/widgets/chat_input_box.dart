import 'package:edu_chatbot/local_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';


class ChatInputBox extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend, onClickCamera;

  const ChatInputBox({
    super.key,
    this.controller,
    this.onSend,
    this.onClickCamera,
  });

  @override
  Widget build(BuildContext context) {
    Prefs prefs = GetIt.instance<Prefs>();
    var index = prefs.getColorIndex();
    var color = getColors().elementAt(index);
    return Card(
      margin: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (onClickCamera != null)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: IconButton(
                  onPressed: onClickCamera,
                  color: Theme.of(context).colorScheme.onSecondary,
                  icon: const Icon(Icons.file_copy_rounded)),
            ),
          Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 6,
                            cursorColor: Theme.of(context).colorScheme.inversePrimary,
                            textInputAction: TextInputAction.newline,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                hintText: 'Message',
                border: InputBorder.none,
                            ),
                            onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
                          ),
              )),
          Padding(
            padding: const EdgeInsets.all(4),
            child: FloatingActionButton.small(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: onSend,
              child: Icon(
                Icons.send_rounded,
                color: isColorDark(color) ? Colors.white : Colors.black,
              ),
            ),
          )
        ],
      ),
    );
  }
}
