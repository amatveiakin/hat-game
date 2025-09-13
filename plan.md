# Taboo Game Mode Implementation Plan

## Overview
Implement a taboo game mode where players explain words without using 5 randomly selected forbidden words that are displayed alongside the main word. The forbidden words are drawn from a pool of taboo words associated with each main word.

## Current State Analysis

### ✅ What's Already Implemented
1. **Taboo Infrastructure**:
   - `GameVariant.taboo` enum value exists in `game_config.dart`
   - `WordContent.taboo()` factory method and `forbiddenWords` field in `word.dart`
   - Taboo lexicon loading in `lexicon.dart` (lines 297-305)
   - Taboo word generation tools in Python (`tools/llm/taboo_words.py`)
   - Sample taboo lexicon file (`hatgame/lexicon/russian_taboo_easy.yaml`)

2. **Word Display System**:
   - Current word shown via `gameData.currentWordContent()` in `game_view.dart:608`
   - Word content accessed through `_wordContent()` in `game_data.dart:391-406`
   - Word selection in `drawNextWord()` in `game_controller.dart:156-185`

3. **Game Configuration**:
   - Game variant selector UI exists but taboo option is missing from `rules_config_view.dart:17-40`

### ❌ What's Missing
1. **UI Components**: Taboo option in game variant selector, forbidden words display
2. **Word Selection Logic**: Integration of taboo lexicons into word collection system
3. **Forbidden Word Selection**: Logic to randomly select 5 forbidden words from available pool
4. **Game Flow Integration**: Taboo mode support in word generation and display

## Implementation Plan

### Phase 1: Configuration & UI Setup
**Files to modify**: `rules_config_view.dart`, `translations/en.yaml`, `translations/ru.yaml`

1. **Add taboo option to game variant selector**:
   - Add taboo option to `getGameVariantOptions()` in `rules_config_view.dart`
   - Add translation strings for taboo variant name and description
   - Ensure taboo option is enabled in both online and offline modes

2. **Update lexicon initialization**:
   - Add taboo lexicons to `Lexicon.init()` in `lexicon.dart`
   - Currently only loads standard dictionaries - need to add `russian_taboo_easy` etc.

### Phase 2: Word Collection & Selection Logic
**Files to modify**: `lexicon.dart`, `game_controller.dart`

1. **Extend word collection system**:
   - Modify `wordCollection()` method to support taboo dictionaries
   - Update `_makeUnionCollection()` to handle taboo word format
   - Ensure taboo words are properly loaded with their forbidden word lists

2. **Update word generation logic**:
   - Modify `_generateRandomWords()` in `game_controller.dart` to use taboo collections when `GameVariant.taboo`
   - Modify `drawNextWord()` to handle taboo word content appropriately

### Phase 3: Forbidden Word Selection & Display
**Files to modify**: `game_view.dart`, `game_controller.dart`, potentially new UI components

1. **Implement forbidden word selection**:
   - When a taboo word is selected, randomly choose 5 forbidden words from its `forbiddenWords` list
   - Store selected forbidden words in the `WordContent` object
   - Handle cases where a word has fewer than 5 forbidden words (use all available)

2. **Create forbidden words display UI**:
   - Design component to show 5 forbidden words below/above the main word
   - Integrate into `game_view.dart` explain phase UI (around line 607-628)
   - Style consistently with existing game UI

### Phase 4: Integration & Testing
**Files to modify**: Various, plus testing

1. **Complete integration**:
   - Ensure taboo mode works with both `fixedWordSet` and `fixedNumRounds` game extents
   - Verify compatibility with all teaming modes
   - Test online/offline mode compatibility

2. **Edge case handling**:
   - Handle words with insufficient forbidden words
   - Ensure proper fallback behavior
   - Validate taboo lexicon format and loading

## Technical Implementation Details

### Word Selection Algorithm
```dart
// In drawNextWord() when GameVariant.taboo:
if (config.rules.variant == GameVariant.taboo) {
  final wordCollection = Lexicon.wordCollection(
      config.rules.dictionaries.toList(),
      false); // pluralias=false for taboo
  WordContent content = wordCollection.randomWord();

  // Select 5 random forbidden words from available pool
  if (content.forbiddenWords != null && content.forbiddenWords!.isNotEmpty) {
    final availableForbidden = content.forbiddenWords!.toList();
    availableForbidden.shuffle(Random());
    final selectedForbidden = availableForbidden.take(5).toBuiltList();
    content = content.rebuild((b) => b..forbiddenWords = selectedForbidden);
  }

  // Continue with existing word creation logic...
}
```

### UI Layout for Forbidden Words
```dart
// In game_view.dart explain phase:
Column(children: [
  // Main word (existing)
  WideButton(...),

  // Forbidden words (new)
  if (wordContent.forbiddenWords != null &&
      wordContent.forbiddenWords!.isNotEmpty)
    Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Wrap(
        children: wordContent.forbiddenWords!.map((word) =>
          Chip(
            label: Text(word),
            backgroundColor: Colors.red.shade100,
          )
        ).toList(),
      ),
    ),

  // Timer (existing)
  ...
])
```

### Dictionary Loading Updates
```dart
// In Lexicon.init():
for (final dictKey in [
  'russian_easy', 'russian_medium', 'russian_hard', 'russian_neo',
  'english_easy', 'english_medium', 'english_hard',
  'russian_taboo_easy', // Add taboo dictionaries
]) {
  // existing loading logic
}
```

## Risk Assessment & Mitigation

### High Risk
1. **Performance**: Loading large taboo dictionaries might slow initialization
   - *Mitigation*: Lazy loading, caching, profiling
2. **UI Layout**: Forbidden words might not fit well on smaller screens
   - *Mitigation*: Responsive design, scrollable layout, testing on various screen sizes

### Medium Risk
1. **Dictionary Availability**: Limited taboo dictionaries currently available
   - *Mitigation*: Start with existing `russian_taboo_easy`, create English equivalent
2. **Word Selection Balance**: Some words might have very few forbidden words
   - *Mitigation*: Graceful degradation, minimum forbidden word requirements

### Low Risk
1. **Game Balance**: Taboo mode might be too hard/easy
   - *Mitigation*: Playtesting, adjustable difficulty settings in future

## Success Criteria

1. **Functional**:
   - Players can select taboo mode in game configuration
   - Taboo words display correctly with 5 forbidden words
   - Game flow works identically to standard mode except for word display

2. **Technical**:
   - No performance regression in app startup or gameplay
   - Proper error handling for edge cases
   - Code follows existing patterns and conventions

3. **User Experience**:
   - Forbidden words are clearly visible and readable
   - UI layout remains clean and functional
   - Mode selection is intuitive and well-documented

## Timeline Estimate
- **Phase 1**: 2-3 hours (UI configuration)
- **Phase 2**: 3-4 hours (word collection logic)
- **Phase 3**: 4-5 hours (forbidden word selection & display)
- **Phase 4**: 2-3 hours (integration & testing)
- **Total**: 11-15 hours

## Files to be Modified
1. `hatgame/lib/rules_config_view.dart` - Add taboo variant option
2. `hatgame/lib/lexicon.dart` - Load taboo dictionaries, update word collection
3. `hatgame/lib/game_controller.dart` - Update word generation for taboo mode
4. `hatgame/lib/game_view.dart` - Add forbidden words display UI
5. `hatgame/translations/en.yaml` - Add English translations
6. `hatgame/translations/ru.yaml` - Add Russian translations
7. `hatgame/lexicon/english_taboo_easy.yaml` - Create English taboo dictionary (if needed)

---

## Self-Critique

**Strengths of this plan:**
- Comprehensive analysis of existing infrastructure
- Clear phase-by-phase approach with specific file targets
- Detailed technical implementation examples
- Risk assessment with mitigation strategies
- Realistic timeline estimates

**Potential improvements:**
- Could include more specific UI mockups or wireframes
- Might benefit from more detailed testing strategy
- Could consider internationalization aspects more thoroughly
- May need more consideration of accessibility features

**Missing considerations:**
- Analytics/telemetry for taboo mode usage
- Future extensibility for other word game variants
- Potential for user-generated taboo word lists
- Performance benchmarking methodology

The plan provides a solid foundation for implementation while maintaining flexibility for adjustments during development.
