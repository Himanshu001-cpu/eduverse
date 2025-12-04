class Validators {
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email';
    return null;
  }

  static String? number(String? value) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) return 'Must be a number';
    return null;
  }
}
