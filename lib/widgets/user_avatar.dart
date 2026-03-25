import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String avatar;
  final bool isOnline;
  final double size;

  const UserAvatar({
    super.key,
    required this.avatar,
    this.isOnline = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              avatar,
              style: TextStyle(
                fontSize: size * 0.6,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
