// src/cache.ts — process-wide lazy cache.
// SettingsLoader.load() is called from every async web handler.

export interface Settings {
    apiKey: string;
    region: string;
}

let cached: Settings | undefined = undefined;

export class SettingsLoader {
    static async load(): Promise<Settings> {
        if (cached === undefined) {
            const fresh = await readSettingsFromDisk();
            cached = fresh;
        }
        return cached;
    }

    static invalidate(): void {
        cached = undefined;
    }
}

declare function readSettingsFromDisk(): Promise<Settings>;
