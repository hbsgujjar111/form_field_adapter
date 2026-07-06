import 'package:flutter/material.dart';
import 'package:form_field_adapter/form_field_adapter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormFieldAdapter Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const FormDemoPage(),
    );
  }
}

class FormDemoPage extends StatefulWidget {
  const FormDemoPage({super.key});

  @override
  State<FormDemoPage> createState() => _FormDemoPageState();
}

class _FormDemoPageState extends State<FormDemoPage> {
  final _formKey = GlobalKey<FormState>();

  // Form State Values
  String? _avatarUrl;
  int _rating = 0;
  List<String> _selectedSkills = [];
  bool _acceptTerms = false;

  // FocusNodes to demonstrate focus-aware border animations
  final FocusNode _avatarFocusNode = FocusNode();
  final FocusNode _ratingFocusNode = FocusNode();
  final FocusNode _skillsFocusNode = FocusNode();

  @override
  void dispose() {
    _avatarFocusNode.dispose();
    _ratingFocusNode.dispose();
    _skillsFocusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Registration Successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fix the highlighted errors.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FormFieldAdapter Examples'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Complete Your Developer Profile',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ==========================================
                // EXAMPLE 1: Circular Avatar Image Picker
                // ==========================================
                FormFieldAdapter<String?>(
                  initialValue: _avatarUrl,
                  focusNode: _avatarFocusNode,
                  validator: (value) =>
                      value == null ? 'Profile picture is required' : null,
                  onSaved: (value) => _avatarUrl = value,

                  // Align everything to the center
                  crossAxisAlignment: CrossAxisAlignment.center,
                  errorPadding: const EdgeInsets.only(top: 8),

                  // Remove the left offset
                  normalDecoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.transparent, width: 3),
                    ),
                  ),
                  focusedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  errorDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.error,
                      width: 3,
                    ),
                  ),
                  focusedErrorDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.error,
                      width: 4,
                    ),
                  ),
                  builder: (state) {
                    return Focus(
                      focusNode: _avatarFocusNode,
                      child: GestureDetector(
                        onTap: () {
                          state.didChange('https://picsum.photos/200');
                          _avatarFocusNode.requestFocus();
                        },
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: state.value != null
                              ? NetworkImage(state.value!)
                              : null,
                          child: state.value == null
                              ? const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ==========================================
                // EXAMPLE 2: Star Rating Selector
                // ==========================================
                Text(
                  'How would you rate your Flutter experience?',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FormFieldAdapter<int>(
                  initialValue: _rating,
                  focusNode: _ratingFocusNode,
                  validator: (value) {
                    if (value == null || value == 0)
                      return 'Please provide a rating';
                    if (value < 3)
                      return 'Must be at least a 3-star rating to join';
                    return null;
                  },
                  onSaved: (value) => _rating = value ?? 0,

                  // Align the bottom line and error text to the center
                  crossAxisAlignment: CrossAxisAlignment.center,
                  errorPadding: const EdgeInsets.only(top: 6),

                  // Remove the left offset
                  decorationPlacement: DecorationPlacement.foreground,
                  builder: (state) {
                    final currentRating = state.value ?? 0;
                    return Focus(
                      focusNode: _ratingFocusNode,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < currentRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: () {
                              state.didChange(index + 1);
                              _ratingFocusNode.requestFocus();
                            },
                          );
                        }),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ==========================================
                // EXAMPLE 3: Multi-Select Tech Tags
                // ==========================================
                Text(
                  'Select your preferred languages (at least 2):',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FormFieldAdapter<List<String>>(
                  initialValue: _selectedSkills,
                  focusNode: _skillsFocusNode,
                  validator: (value) {
                    if (value == null || value.length < 2) {
                      return 'Select at least 2 technologies';
                    }
                    return null;
                  },
                  onSaved: (value) => _selectedSkills = value ?? [],
                  // Custom container background transitions
                  normalDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  focusedDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  builder: (state) {
                    final currentSkills = state.value ?? [];
                    final options = [
                      'Dart',
                      'Kotlin',
                      'Swift',
                      'TypeScript',
                      'Go',
                      'Python',
                    ];

                    return Focus(
                      focusNode: _skillsFocusNode,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: options.map((option) {
                            final isSelected = currentSkills.contains(option);
                            return FilterChip(
                              label: Text(option),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                _skillsFocusNode.requestFocus();
                                final newList = List<String>.from(
                                  currentSkills,
                                );
                                if (selected) {
                                  newList.add(option);
                                } else {
                                  newList.remove(option);
                                }
                                state.didChange(newList);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ==========================================
                // EXAMPLE 4: Accept Terms Switch Card
                // ==========================================
                FormFieldAdapter<bool>(
                  initialValue: _acceptTerms,
                  validator: (value) => value == true
                      ? null
                      : 'You must accept the terms to proceed',
                  onSaved: (value) => _acceptTerms = value ?? false,
                  // We don't want a border wrapper at all for this card, so we hide it.
                  normalDecoration: const BoxDecoration(),
                  errorDecoration: const BoxDecoration(),
                  builder: (state) {
                    return Card(
                      color: state.hasError
                          ? theme.colorScheme.errorContainer.withValues(
                              alpha: .3,
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'I agree to the Terms of Service & Privacy Policy',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Switch(
                              value: state.value ?? false,
                              onChanged: (value) => state.didChange(value),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text(
                      'Register Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
