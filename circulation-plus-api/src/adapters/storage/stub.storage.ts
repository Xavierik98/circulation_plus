import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import type { StorageProvider } from '../types';

// Stub stockage : écrit le fichier sur le disque local et renvoie une URL
// réellement résolvable (servie par la route dev ${BASE_URL}/__stub_storage/<key>).
export class StubStorageProvider implements StorageProvider {
  readonly mode = 'stub' as const;
  static readonly DIR = '.storage-stub';

  constructor(private readonly baseUrl: string) {}

  async upload(
    key: string,
    bytes: Buffer,
    _contentType: string,
  ): Promise<{ key: string }> {
    const filePath = join(StubStorageProvider.DIR, key);
    await mkdir(dirname(filePath), { recursive: true });
    await writeFile(filePath, bytes);
    return { key };
  }

  async signedUrl(key: string, _expiresInSeconds: number): Promise<string> {
    return `${this.baseUrl}/__stub_storage/${key}`;
  }
}
