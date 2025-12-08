# English Translation Field Update

## Summary
Updated the `FARMER_QUERY_PROCESS_SYSTEM_MESSAGE` to clarify that `english_translation` is the **PRIMARY QUERY** for all downstream processing, not just a translation field.

## Key Changes

### 1. Strict Rule #7 - New Critical Instruction
```
**CRITICAL: "english_translation" is the PRIMARY QUERY for all processing:**
- This field will be used for final model generation
- This field will be used for scheme optimization with Gemini
- This field will be used for all downstream context retrieval
- Make it comprehensive and include all relevant context from conversation
```

### 2. Enhanced JSON Format Documentation
```json
{
  "english_translation": "REQUIRED for regional language queries - This becomes the PRIMARY query used for: model generation, scheme optimization, and all context retrieval. Include conversation context and make it comprehensive."
}
```

### 3. Added Important Notes Section
- For Malayalam/Hindi/regional queries: ALWAYS provide english_translation
- This field is NOT just translation - it's the MAIN PROCESSING QUERY
- Include conversation context and clarifications in english_translation
- The system will use english_translation for: Gemini generation, scheme optimization, vector search
- Make it detailed and context-aware

### 4. Enhanced Examples
Updated all Malayalam examples to show comprehensive `english_translation` with:
- Location context included
- Detailed query expansion
- Conversation context integration

Example:
```
Query: "വാഴയിൽ ഇലത്തഴമ്പ് കണ്ടു എന്ത് ചെയ്യണം?"
→ {
  "english_translation": "I saw leaf spot disease on my banana plants in Kerala, what treatment should I apply?"
}
```
(Includes location "Kerala" and expands "leaf spot" to "leaf spot disease")

### 5. Added Conversation Context Example
```
Last Response: "നെല്ല് കൃഷിക്ക് നല്ല ജല പരിപാലനം ആവശ്യമാണ്..."
Current Query: "വളം എന്താണ് ഉപയോഗിക്കേണ്ടത്?"
→ {
  "english_translation": "What fertilizer should I use for rice cultivation in Kerala? The conversation is about rice farming."
}
```
(Shows how conversation context should be included in english_translation)

## Impact on System Behavior

### Before
- `english_translation` was just a translation
- Pipeline used original query for processing
- Context was sometimes lost in translation

### After
- `english_translation` is the **main processing query**
- All components (model generation, scheme optimization, vector search) use `english_translation`
- Context is preserved and enhanced
- Better query understanding across the pipeline

## Usage Scenarios

### Scenario 1: Regional Language Query
**Input:** "വാഴയിൽ ഇലത്തഴമ്പ് കണ്ടു എന്ത് ചെയ്യണം?"
**english_translation:** "I saw leaf spot disease on my banana plants in Kerala, what treatment should I apply?"
**Used for:**
- Vector DB search
- Gemini model generation
- Scheme optimization

### Scenario 2: Follow-up Query with Context
**Last Response:** "Rice needs proper water management..."
**Input:** "What about fertilizer?"
**english_translation:** "What fertilizer should I use for rice cultivation in Kerala? The conversation is about rice farming."
**Result:** Context-aware response about rice fertilizer

### Scenario 3: English Query Enhancement
**Input:** "What is the price of coconut today?"
**english_translation:** "What is the current market price of coconut in Kerala mandis today?"
**Result:** More specific query for better eNAM search

## Developer Notes
- The pipeline should ALWAYS use `english_translation` if available
- If `english_translation` is present, it takes precedence over the original query
- Gemini should make `english_translation` comprehensive and context-rich
- This improves accuracy across all pipeline components

## Testing
Test queries should verify:
1. Regional language queries get comprehensive `english_translation`
2. `english_translation` includes conversation context
3. `english_translation` is used for model generation
4. `english_translation` is used for scheme optimization
5. Location and state info included in `english_translation`
