enum StoryStatus {
  draft,
  published,
  archived,
}

class Story {
  final String id;
  final String title;
  final String type;
  final DateTime lastEdited;
  StoryStatus status;
  final String? coverImage;
  final List<Chapter>? chapters;

  Story({
    required this.id,
    required this.title,
    required this.type,
    required this.lastEdited,
    required this.status,
    this.coverImage,
    this.chapters,
  });
}

class Chapter {
  final String id;
  final String title;
  bool isComplete;

  Chapter({
    required this.id,
    required this.title,
    required this.isComplete,
  });
}
