import 'package:flutter/material.dart';
class SaveButton extends StatelessWidget {
  final VoidCallBack? onPressed; // this should help with errors and allow callback 
  const SaveButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("save"),
            content: const Text("do you want to save this Sheet?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  if (onPressed != null) {
                    onPressed!();
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
      child: const Text("Save"),
    );
  }
}