# 11_gender — Reduce gender options to Male / Female only

## Ask

> I want only two options male, female for gender area on "Edit profile" dialog.

---

## What changed

**`flutter_app/lib/features/settings/edit_profile_dialog.dart`**

Reduced `_genders` from four options to two:

```dart
// Before
static const _genders = [
  ('female', 'Female'),
  ('male', 'Male'),
  ('nonbinary', 'Non-binary'),
  ('unspecified', 'Prefer not to say'),
];
String _gender = 'unspecified';

// initState
_gender = user.gender.isEmpty ? 'unspecified' : user.gender;

// After
static const _genders = [
  ('female', 'Female'),
  ('male', 'Male'),
];
String _gender = 'female';

// initState
final g = user.gender;
_gender = (g == 'male' || g == 'female') ? g : 'female';
```

The default and the `initState` guard both use `'female'` as the fallback for any user
who previously had `'nonbinary'` or `'unspecified'` stored — so the radio group always
lands on a valid option and no validation errors occur on save.

The `RadioGroup<String>` widget in the build method needed no changes; it renders whatever
entries `_genders` contains.

---

## Files changed

| File | Change |
|------|--------|
| [flutter_app/lib/features/settings/edit_profile_dialog.dart](../../flutter_app/lib/features/settings/edit_profile_dialog.dart) | `_genders` trimmed to 2 entries; default + initState guard updated |
