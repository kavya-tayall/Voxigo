import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MusicStoriesPage(),
    );
  }
}

class MusicStoriesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Music'),
              Tab(text: 'Stories'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // Music Tab
            ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Music ${index + 1}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MusicDetailPage(
                          title: 'Music ${index + 1}',
                          imageUrl: 'assets/music_image.png', // Replace with your actual image path
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Stories Tab
            ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Story ${index + 1}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryDetailPage(
                          title: 'Story ${index + 1}',
                          content: 'This is the content of Story ${index + 1}', // Replace with your actual story content
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MusicDetailPage extends StatelessWidget {
  final String title;
  final String imageUrl;

  MusicDetailPage({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(imageUrl), // Display the image
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Add playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  onPressed: () {
                    // Handle rewind
                  },
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: () {
                    // Handle play
                  },
                ),
                IconButton(
                  icon: Icon(Icons.forward_10),
                  onPressed: () {
                    // Handle fast forward
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StoryDetailPage extends StatelessWidget {
  final String title;
  final String content;

  StoryDetailPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              // Handle play audio narration
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}