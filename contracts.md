# Rule and Rule Form Contract

Every renaming rule is two parts that ship together: a **rule model** in
`lib/models/rule.dart` and a **rule form** in `lib/ui/rule_forms/`. This file
describes what each part must do so the add/edit dialog, the preview, the
rename service and saved settings all keep working.

## Rule model

A rule is a subclass of the sealed `Rule` class.

- **Immutable settings.** All settings are `final` fields with defaults in the
  constructor. Use a `const` constructor unless the rule keeps state (see
  `SerializeRule`).
- **`apply(String filename)`** returns the new name for one file name (not a
  path). It must:
  - be pure apart from documented state; it must never touch the disk;
  - return the input unchanged when the rule isn't configured yet (e.g. empty
    search text) or doesn't apply (e.g. a delimiter that isn't in the name);
  - respect `skipExtension` where the rule has it, using `_splitNameAndExt`;
  - count positions in characters, not UTF-16 code units, using
    `Rule._charIndex` / `Rule._advance`, so emoji are never split.
- **`reset()`** clears any state between batches. Stateless rules inherit the
  empty default. The rename service calls it before every batch, so a stateful
  rule must produce the same names every time it is reset.
- **`icon` and `label`** are the single source of the rule's icon and name.
  The add-rule dialog reads them from a default instance; don't repeat them.
- **`toJson()`** writes every setting plus a `$type` discriminator.
- **`fromJson()`** reads every setting with a fallback to the constructor
  default (`json['x'] as bool? ?? true`), so files saved by older versions
  still load.

Then register the rule:

1. Add the `$type` to the switch in `Rule.fromJson`.
2. Add a value to `_RuleType` in `lib/ui/add_rule_dialog.dart` and cover it in
   `_sampleOf`, `initState` and `_buildFormWidget`.

### Saved settings compatibility

Rules are saved to `settings.json` and must keep loading after upgrades.

- Never rename or reuse a `$type`, a JSON key or an enum value name.
- A new setting must default to the behaviour that existed before it.
- Removing a setting is fine; unknown keys are ignored.
- If a saved rule can't be read anyway, `RulePersistence.load` skips it and
  backs up the file, so don't throw for recoverable problems.

## Rule form

A form edits one rule type. It is a `StatefulWidget` named
`<Name>RuleWidget` with exactly this constructor:

```dart
const FindReplaceRuleWidget({
  super.key,
  this.initial,                 // FindReplaceRule? – the rule being edited
  required this.onChanged,      // ValueChanged<FindReplaceRule>
});
```

The form must:

- **Start from `initial`.** Initialise every field from `initial`, falling back
  to the same defaults as the rule's constructor. `initial` is null when
  adding a rule.
- **Emit a complete rule on every change.** Build a new rule from all fields
  and pass it to `onChanged`, for text edits (controller listeners) and for
  every checkbox, radio or dropdown change. Never emit a partial rule.
- **Not emit on start-up.** The dialog's Add/Save button stays disabled until
  the first `onChanged`, so opening and closing the dialog changes nothing.
- **Hold no renaming logic.** Building the rule is the form's only job; what
  the rule does to a name belongs in `apply`. Validation that only the model
  can know (like `RegexRule.isExpressionValid`) lives on the model, and the
  dialog uses it to keep the confirm button disabled.
- **Dispose** its controllers and remove its listeners.
- **Look like the other forms**: inputs first, then a settings section of
  dense `CheckboxListTile`s, including "Skip file extension" when the rule
  has `skipExtension`.

## Tests

Every rule needs focused tests in `test/rule_test.dart` for:

- normal input, empty input and boundary positions;
- each setting, including `skipExtension`;
- a `toJson` / `fromJson` round trip (add it to the `serialization` group);
- `reset()` behaviour for stateful rules.
