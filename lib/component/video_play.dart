// import 'package:flutter/material.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
//
// class VideoPlayerWidget extends StatefulWidget {
//   @override
//   _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
// }
//
// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   late VlcPlayerController _vlcPlayerController;
//
//   @override
//   void initState() {
//     super.initState();
//     _vlcPlayerController = VlcPlayerController.network(
//       'https://www.w3schools.com/html/mov_bbb.mp4', // Replace with your video URL
//       hwAcc: HwAcc.full, // Enable hardware acceleration
//       autoPlay: true,
//       options: VlcPlayerOptions(),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _vlcPlayerController.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: VlcPlayer(
//           controller: _vlcPlayerController,
//           aspectRatio: 16 / 9,
//           virtualDisplay: true,
//         ),
//       ),
//     );
//   }
// }
