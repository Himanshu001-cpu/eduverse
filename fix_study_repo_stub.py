import re

file_path = "lib/study/study_repository.dart"
with open(file_path, "r") as f:
    content = f.read()

new_method = """  @override
  Future<List<StudyLiveClass>> getLiveClasses(String courseId, String batchId) async {
    return [];
  }"""

if "Future<List<StudyLiveClass>> getLiveClasses" not in content:
    content = content.replace("  @override\n  Future<void> enrollStudent", f"{new_method}\n\n  @override\n  Future<void> enrollStudent")

with open(file_path, "w") as f:
    f.write(content)
