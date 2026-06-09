/**
 * Parses JSON from an LLM chat completion `content` string.
 * Handles bare JSON and ```json fenced blocks.
 */
export function parseAiJsonContent(raw: string): unknown {
  const trimmed = raw.trim();
  if (!trimmed) {
    throw new Error("empty content");
  }

  try {
    return JSON.parse(trimmed);
  } catch {
    // continue
  }

  const fenced = /^```(?:json)?\s*([\s\S]*?)```\s*$/i.exec(trimmed);
  if (fenced) {
    return JSON.parse(fenced[1]!.trim());
  }

  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start >= 0 && end > start) {
    return JSON.parse(trimmed.slice(start, end + 1));
  }

  throw new Error("no JSON object in content");
}
