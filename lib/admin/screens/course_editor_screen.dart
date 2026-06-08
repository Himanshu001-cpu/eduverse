import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/thumbnail_upload_widget.dart';
import '../utils/validators.dart';

class CourseEditorScreen extends StatefulWidget {
  final AdminCourse? course;
  const CourseEditorScreen({super.key, this.course});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _subtitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _emojiController;
  late TextEditingController _realPriceController;
  late TextEditingController _finalPriceController;
  late TextEditingController _seatsTotalController;
  late TextEditingController _seatsLeftController;
  DateTime? _startDate;
  DateTime? _endDate;

  String _visibility = 'draft';
  String _level = 'beginner';
  String _language = 'en';

  Color _gradientStart = Colors.blue;
  Color _gradientEnd = Colors.blueAccent;
  String _thumbnailUrl = '';

  bool _isLoading = false;

  final List<String> _visibilityOptions = ['draft', 'published', 'archived'];
  final List<String> _levelOptions = ['beginner', 'intermediate', 'advanced'];
  final List<String> _languageOptions = ['en', 'hi', 'bn', 'ta', 'te', 'mr'];

  // Predefined color options for gradient
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    final course = widget.course;

    _titleController = TextEditingController(text: course?.title ?? '');
    _slugController = TextEditingController(text: course?.slug ?? '');
    _subtitleController = TextEditingController(text: course?.subtitle ?? '');
    _descriptionController = TextEditingController(
      text: course?.description ?? '',
    );
    _emojiController = TextEditingController(text: course?.emoji ?? '📚');
    _realPriceController = TextEditingController(
      text: course?.realPrice?.toString() ?? course?.priceDefault.toString() ?? '0',
    );
    _finalPriceController = TextEditingController(
      text: course?.finalPrice?.toString() ?? course?.priceDefault.toString() ?? '0',
    );
    _seatsTotalController = TextEditingController(
      text: course?.seatsTotal?.toString() ?? '',
    );
    _seatsLeftController = TextEditingController(
      text: course?.seatsLeft?.toString() ?? '',
    );
    _startDate = course?.startDate;
    _endDate = course?.endDate;

    _visibility = course?.visibility ?? 'draft';
    _level = course?.level ?? 'beginner';
    _language = course?.language ?? 'en';

    if (course != null && course.gradientColors.length >= 2) {
      _gradientStart = Color(course.gradientColors[0]);
      _gradientEnd = Color(course.gradientColors[1]);
    }

    _thumbnailUrl = course?.thumbnailUrl ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _emojiController.dispose();
    _realPriceController.dispose();
    _finalPriceController.dispose();
    _seatsTotalController.dispose();
    _seatsLeftController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newCourse = AdminCourse(
        id: widget.course?.id ?? '',
        title: _titleController.text.trim(),
        slug: _slugController.text.trim().isEmpty
            ? _titleController.text.trim().toLowerCase().replaceAll(' ', '-')
            : _slugController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _emojiController.text.trim().isEmpty
            ? '📚'
            : _emojiController.text.trim(),
        tags: [],
        language: _language,
        level: _level,
        thumbnailUrl: _thumbnailUrl,
        gradientColors: [_gradientStart.toARGB32(), _gradientEnd.toARGB32()],
        priceDefault: double.tryParse(_finalPriceController.text) ?? 0.0,
        realPrice: double.tryParse(_realPriceController.text) ?? 0.0,
        finalPrice: double.tryParse(_finalPriceController.text) ?? 0.0,
        seatsTotal: int.tryParse(_seatsTotalController.text),
        seatsLeft: int.tryParse(_seatsLeftController.text),
        startDate: _startDate,
        endDate: _endDate,
        visibility: _visibility,
        createdAt: widget.course?.createdAt ?? DateTime.now(),
      );

      await context.read<FirebaseAdminService>().saveCourse(
        newCourse,
        isNew: widget.course == null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Course ${widget.course == null ? 'created' : 'updated'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.course == null ? 'New Course' : 'Edit Course',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Card
                    _buildPreviewCard(),
                    const SizedBox(height: 24),

                    // Basic Info Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course Title *',
                        hintText: 'e.g., UPSC Prelims 2025',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.required,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle *',
                        hintText: 'e.g., Complete preparation guide',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.required,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _slugController,
                      decoration: const InputDecoration(
                        labelText: 'Slug (URL-friendly ID)',
                        hintText: 'Auto-generated from title if empty',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Detailed course description...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // Appearance Section
                    _buildSectionHeader('Appearance'),
                    const SizedBox(height: 12),

                    // Thumbnail Upload
                    ThumbnailUploadWidget(
                      currentUrl: _thumbnailUrl,
                      storagePath: 'courses/thumbnails',
                      onUploaded: (url) => setState(() => _thumbnailUrl = url),
                    ),
                    const SizedBox(height: 20),

                    // Emoji field and quick picker
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Emoji Field
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _emojiController,
                            decoration: const InputDecoration(
                              labelText: 'Emoji *',
                              hintText: '📚',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        // Quick emoji picker
                        ...[
                          '📚',
                          '✍️',
                          '📊',
                          '⚖️',
                          '🏛️',
                          '🧮',
                          '🌍',
                          '💼',
                        ].map(
                          (e) => InkWell(
                            onTap: () {
                              _emojiController.text = e;
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gradient Colors
                    const Text(
                      'Gradient Colors',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Color',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              _buildColorPicker(
                                _gradientStart,
                                (c) => setState(() => _gradientStart = c),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Color',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              _buildColorPicker(
                                _gradientEnd,
                                (c) => setState(() => _gradientEnd = c),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pricing & Settings Section
                    _buildSectionHeader('Pricing & Settings'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _realPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Original/Real Price (₹) *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: Validators.required,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _finalPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Final/Discounted Price (₹) *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: Validators.required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _seatsTotalController,
                            decoration: const InputDecoration(
                              labelText: 'Total Seats (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _seatsLeftController,
                            decoration: const InputDecoration(
                              labelText: 'Seats Left (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              alignment: Alignment.centerLeft,
                            ),
                            label: Text(_startDate == null ? 'Start Date' : 'Starts: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 90)),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              alignment: Alignment.centerLeft,
                            ),
                            label: Text(_endDate == null ? 'End Date' : 'Ends: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _visibility,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Visibility *',
                              border: OutlineInputBorder(),
                            ),
                            items: _visibilityOptions
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          v == 'published'
                                              ? Icons.public
                                              : v == 'draft'
                                              ? Icons.edit
                                              : Icons.archive,
                                          size: 16,
                                          color: v == 'published'
                                              ? Colors.green
                                              : v == 'draft'
                                              ? Colors.orange
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            v.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _visibility = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _level,
                            decoration: const InputDecoration(
                              labelText: 'Level',
                              border: OutlineInputBorder(),
                            ),
                            items: _levelOptions
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(
                                      l[0].toUpperCase() + l.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _level = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _language,
                            decoration: const InputDecoration(
                              labelText: 'Language',
                              border: OutlineInputBorder(),
                            ),
                            items: _languageOptions.map((l) {
                              final labels = {
                                'en': 'English',
                                'hi': 'Hindi',
                                'bn': 'Bengali',
                                'ta': 'Tamil',
                                'te': 'Telugu',
                                'mr': 'Marathi',
                              };
                              return DropdownMenuItem(
                                value: l,
                                child: Text(labels[l] ?? l),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _language = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.course == null
                            ? 'Create Course'
                            : 'Save Changes',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _gradientStart.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: Thumbnail or Gradient
            _thumbnailUrl.isNotEmpty
                ? Image.network(
                    _thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildGradientPreview(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildGradientPreview(showLoader: true);
                    },
                  )
                : _buildGradientPreview(),
            // Dark overlay for text readability
            if (_thumbnailUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_thumbnailUrl.isEmpty)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _emojiController.text.isEmpty
                              ? '📚'
                              : _emojiController.text,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  if (_thumbnailUrl.isEmpty) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _titleController.text.isEmpty
                              ? 'Course Title'
                              : _titleController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitleController.text.isEmpty
                              ? 'Subtitle goes here'
                              : _subtitleController.text,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPreview({bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: showLoader
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            )
          : null,
    );
  }

  Widget _buildColorPicker(Color selected, ValueChanged<Color> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colorOptions.map((color) {
        final isSelected = selected.toARGB32() == color.toARGB32();
        return InkWell(
          onTap: () => onChanged(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : Border.all(color: Colors.grey.shade300),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
