/// A question paper document from the `papers` collection.
class Paper {
  final String id;
  final String? title;
  final String paperName;
  final String courseCode;
  final String department;
  final int? year;
  final String? semester;
  final String? examType;
  final String? paperType;
  final String? programme;
  final String? stream;
  final String? institute;
  final String fileId;
  final String fileUrl;
  final int downloadCount;
  final int viewCount;

  Paper({
    required this.id,
    required this.paperName,
    required this.courseCode,
    required this.department,
    required this.fileId,
    required this.fileUrl,
    this.title,
    this.year,
    this.semester,
    this.examType,
    this.paperType,
    this.programme,
    this.stream,
    this.institute,
    this.downloadCount = 0,
    this.viewCount = 0,
  });

  /// Display title: prefer paper_name, fall back to title, then course code.
  String get displayTitle {
    if (paperName.trim().isNotEmpty) return paperName;
    if (title != null && title!.trim().isNotEmpty) return title!;
    return courseCode;
  }

  factory Paper.fromJson(Map<String, dynamic> j) {
    return Paper(
      id: (j['\$id'] ?? '').toString(),
      title: j['title']?.toString(),
      paperName: (j['paper_name'] ?? '').toString(),
      courseCode: (j['course_code'] ?? '').toString(),
      department: (j['department'] ?? '').toString(),
      year: j['year'] is int ? j['year'] as int : int.tryParse('${j['year']}'),
      semester: j['semester']?.toString(),
      examType: j['exam_type']?.toString(),
      paperType: j['paper_type']?.toString(),
      programme: j['programme']?.toString(),
      stream: j['stream']?.toString(),
      institute: (j['institute'] ?? j['institution'])?.toString(),
      fileId: (j['file_id'] ?? '').toString(),
      fileUrl: (j['file_url'] ?? '').toString(),
      downloadCount: (j['download_count'] as int?) ?? 0,
      viewCount: (j['view_count'] as int?) ?? 0,
    );
  }
}

/// A syllabus library entry (department PDF) from /api/app/syllabus.
class SyllabusEntry {
  final String id;
  final String subject;
  final String department;
  final String courseName;
  final int? year;
  final String fileUrl;

  SyllabusEntry({
    required this.id,
    required this.subject,
    required this.department,
    required this.courseName,
    required this.fileUrl,
    this.year,
  });

  String get displayName => subject.isNotEmpty ? subject : courseName;

  factory SyllabusEntry.fromJson(Map<String, dynamic> j) {
    return SyllabusEntry(
      id: (j['id'] ?? '').toString(),
      subject: (j['subject'] ?? '').toString(),
      department: (j['department'] ?? '').toString(),
      courseName: (j['course_name'] ?? '').toString(),
      year: j['year'] is int ? j['year'] as int : int.tryParse('${j['year']}'),
      fileUrl: (j['file_url'] ?? '').toString(),
    );
  }
}

/// A single syllabus unit row from /api/syllabus/table.
class SyllabusUnit {
  final int unitNumber;
  final String content;
  final int? lectures;

  SyllabusUnit({required this.unitNumber, required this.content, this.lectures});

  factory SyllabusUnit.fromJson(Map<String, dynamic> j) {
    return SyllabusUnit(
      unitNumber: (j['unit_number'] as int?) ?? (j['unitNumber'] as int?) ?? 0,
      content: (j['syllabus_content'] ?? j['content'] ?? '').toString(),
      lectures: j['lectures'] is int ? j['lectures'] as int : null,
    );
  }
}
