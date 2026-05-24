/// Appended to Gemini look prompts for consistent Lolipants catalogue output.
/// Keep in sync with server default in `geminiImageClient.ts` when possible.
const String kAiLookPromptSuffix = ''
    'Lolipants refine rules: pure solid white background (#FFFFFF). '
    'Keep the EXACT same mannequin, pose, proportions, framing, colours, panels, trim, and slot layout as the primary design-preview reference — do not swap the model or redesign the garment. '
    'Only refine layered configurator graphics into ONE unified photorealistic sewn garment (natural fabric drape, subtle stitching, cohesive material). '
    'No studio set, scenery, props, watermarks, or readable text/logos. SynthID from the API is acceptable.';
