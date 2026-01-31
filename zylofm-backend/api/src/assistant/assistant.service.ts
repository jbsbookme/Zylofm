import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

export const ASSISTANT_LIBRARY_FOLDER = 'zylofm/assistant_library';

function normalizeQuery(query: string): { q: string; tokens: string[] } {
  const q = (query ?? '').trim().toLowerCase();
  const tokens = q
    .split(/\s+/)
    .map((t) => t.trim())
    .filter((t) => t.length >= 2)
    .slice(0, 8);
  return { q, tokens };
}

@Injectable()
export class AssistantService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cloudinary: CloudinaryService,
  ) {}

  private _delegate(): any {
    return (this.prisma as any).assistantLibraryItem;
  }

  async createLibraryItem(params: {
    title: string;
    audioUrl: string;
    keywords?: string[];
    isActive?: boolean;
  }) {
    const title = params.title.trim();
    const audioUrl = params.audioUrl.trim();
    const keywords = (params.keywords ?? []).map((k) => k.trim().toLowerCase()).filter(Boolean);

    const item = await this._delegate().create({
      data: {
        title,
        audioUrl,
        keywords,
        isActive: params.isActive ?? true,
      },
    });

    return {
      id: item.id,
      title: item.title,
      audioUrl: item.audioUrl,
      keywords: item.keywords,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  private _audioAllowed(file: Express.Multer.File): boolean {
    const name = (file.originalname ?? '').toLowerCase();
    const mime = (file.mimetype ?? '').toLowerCase();
    const ext = name.split('.').pop() ?? '';

    if (ext == 'mp3' || ext == 'wav') return true;
    if (mime == 'audio/mpeg' || mime == 'audio/mp3') return true;
    if (mime == 'audio/wav' || mime == 'audio/x-wav') return true;
    return false;
  }

  private _parseKeywords(raw?: string): string[] {
    const v = (raw ?? '').trim();
    if (!v) return [];
    return v
      .split(/[\s,]+/)
      .map((e) => e.trim().toLowerCase())
      .filter((e) => e.length > 0)
      .slice(0, 20);
  }

  async uploadLibraryAudio(params: {
    title: string;
    keywords?: string;
    isActive?: boolean;
    audio?: Express.Multer.File;
  }) {
    const title = params.title.trim();
    if (title.length === 0) throw new BadRequestException('title required');
    if (!params.audio) throw new BadRequestException('audio file required');
    if (!this._audioAllowed(params.audio)) {
      throw new BadRequestException('audio must be mp3 or wav');
    }

    let uploaded;
    try {
      uploaded = await this.cloudinary.uploadBuffer({
        buffer: params.audio.buffer,
        filename: params.audio.originalname,
        folder: ASSISTANT_LIBRARY_FOLDER,
        resourceType: 'video',
        contentType: params.audio.mimetype,
      });
    } catch (e: any) {
      const msg = typeof e?.message === 'string' ? e.message : 'Cloudinary upload failed';
      throw new BadRequestException(msg);
    }

    return this.createLibraryItem({
      title,
      audioUrl: uploaded.secureUrl,
      keywords: this._parseKeywords(params.keywords),
      isActive: params.isActive ?? true,
    });
  }

  async listLibraryItems() {
    const items = await this._delegate().findMany({
      orderBy: { updatedAt: 'desc' },
    });

    return items.map((item) => ({
      id: item.id,
      title: item.title,
      audioUrl: item.audioUrl,
      keywords: item.keywords,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    }));
  }

  async listPublicLibraryItems() {
    const items = await this._delegate().findMany({
      where: { isActive: true },
      orderBy: { updatedAt: 'desc' },
      take: 200,
    });

    return items.map((item) => ({
      id: item.id,
      title: item.title,
      audioUrl: item.audioUrl,
      keywords: item.keywords,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    }));
  }

  async updateLibraryItem(id: string, params: { isActive?: boolean; title?: string; keywords?: string[] }) {
    const existing = await this._delegate().findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Library item not found');

    const data: Record<string, any> = {};

    if (typeof params.isActive === 'boolean') {
      data.isActive = params.isActive;
    }

    if (typeof params.title === 'string') {
      const title = params.title.trim();
      if (!title) throw new BadRequestException('title required');
      data.title = title;
    }

    if (Array.isArray(params.keywords)) {
      data.keywords = params.keywords
        .map((k) => String(k).trim().toLowerCase())
        .filter(Boolean)
        .slice(0, 40);
    }

    if (Object.keys(data).length === 0) {
      return {
        id: existing.id,
        title: existing.title,
        audioUrl: existing.audioUrl,
        keywords: existing.keywords,
        isActive: existing.isActive,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      };
    }

    const next = await this._delegate().update({
      where: { id },
      data,
    });

    return {
      id: next.id,
      title: next.title,
      audioUrl: next.audioUrl,
      keywords: next.keywords,
      isActive: next.isActive,
      createdAt: next.createdAt,
      updatedAt: next.updatedAt,
    };
  }

  async deleteLibraryItem(id: string) {
    const existing = await this._delegate().findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Library item not found');

    await this._delegate().delete({ where: { id } });
    return { ok: true };
  }

  async play(params: { query: string }) {
    const { q, tokens } = normalizeQuery(params.query);
    if (!q) throw new NotFoundException('No match');

    const candidates = await this._delegate().findMany({
      where: {
        isActive: true,
        OR: [
          { title: { contains: q, mode: 'insensitive' } },
          ...(tokens.length > 0 ? [{ keywords: { hasSome: tokens } }] : []),
        ],
      },
      take: 25,
      orderBy: { updatedAt: 'desc' },
    });

    if (candidates.length === 0) throw new NotFoundException('No match');

    const scored = candidates
      .map((item) => {
        const titleLc = item.title.toLowerCase();
        const titleHit = titleLc.includes(q) ? 3 : 0;
        const keywordHits = tokens.reduce((acc, t) => (item.keywords.includes(t) ? acc + 1 : acc), 0);
        return { item, score: titleHit + keywordHits };
      })
      .sort((a, b) => b.score - a.score);

    const best = scored[0]?.item;
    if (!best) throw new NotFoundException('No match');

    return {
      status: 'ok',
      query: params.query,
      audioUrl: best.audioUrl,
      match: {
        id: best.id,
        title: best.title,
        keywords: best.keywords,
      },
    };
  }
}
