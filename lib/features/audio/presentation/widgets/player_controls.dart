import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool autoPlayNext;
  final Function(bool)? onAutoPlayNextChange;
  final VoidCallback onPlayPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onPlayNext;
  final VoidCallback onShowPlaylist;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.autoPlayNext,
    this.onAutoPlayNextChange,
    required this.onPlayPrevious,
    required this.onTogglePlayPause,
    required this.onPlayNext,
    required this.onShowPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Switch(
          value: autoPlayNext,
          onChanged: onAutoPlayNextChange,
          activeThumbColor: Colors.white,
          activeTrackColor: Colors.lightBlue,
          inactiveThumbColor: Colors.white54,
          inactiveTrackColor: Colors.white10,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded,
              color: Colors.white, size: 32),
          onPressed: onPlayPrevious,
        ),

        // Play/Pause (Large White Circle)
        GestureDetector(
          onTap: onTogglePlayPause,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 36,
                  ),
          ),
        ),

        // Next (30 Sec Forward style)
        IconButton(
          icon: const Icon(Icons.skip_next_rounded,
              color: Colors.white, size: 32),
          onPressed: onPlayNext,
        ),
        IconButton(
          icon: const Icon(Icons.playlist_add_check_circle, color: Colors.white),
          onPressed: onShowPlaylist,
        ),
      ],
    );
  }
}