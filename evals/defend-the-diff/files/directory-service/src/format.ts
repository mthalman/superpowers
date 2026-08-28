/**
 * Format a name as "Last, First" for display in the direcotry listing.
 * Trims surrounding whitespace; leaves internal whitespace alone.
 */
export function formatName(first: string, last: string): string {
    return `${last.trim()}, ${first.trim()}`;
}
