import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';

class UserBanners extends StatelessWidget {
  const UserBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () {},
        ),
      ],
      flexibleSpace: Padding(
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UpdateProfileScreen()));
              },
              child: const CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                    "https://lh3.googleusercontent.com/a/AAcHTtcDcIjcAxYbE61EV4D7MPqUxP8TAu7elGBuYFxdmRYAa9M=s288-c-no"),
              ),
            ),
            const SizedBox(width: 15),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mostafejur Rahman",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 2),
                Text("example@gmail.com",
                    style: TextStyle(fontSize: 14, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
