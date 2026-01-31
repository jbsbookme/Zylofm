export function newId(prefix: string): string {
  // No external deps; good enough for in-memory dev.
  const rand = Math.random().toString(16).slice(2);
  return `${prefix}_${Date.now().toString(16)}_${rand}`;
}
