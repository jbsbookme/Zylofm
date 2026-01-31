import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DjStatus, MixStatus, Role } from '../common/types';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { JwtPayload } from '../auth/jwt.strategy';

type Viewer = JwtPayload | undefined;

@Injectable()
export class MixesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cloudinary: CloudinaryService,
  ) {}

  private _allowAdminUpload(): boolean {
    const flag = (process.env.ALLOW_ADMIN_UPLOAD ?? '').trim().toLowerCase();
    const enabled = ['1', 'true', 'yes', 'y', 'on'].includes(flag);
    if (enabled) return true;

    // Default behavior: allow in local/dev, never allow by default in production.
    const nodeEnv = (process.env.NODE_ENV ?? '').trim().toLowerCase();
    return nodeEnv != 'production' && flag !== '0' && flag !== 'false' && flag !== 'off';
  }

  private _audioAllowed(file: Express.Multer.File): boolean {
    const name = (file.originalname ?? '').toLowerCase();
    const mime = (file.mimetype ?? '').toLowerCase();
    const ext = name.split('.').pop() ?? '';

    // PASO 2 allowed formats: mp3,wav
    if (ext === 'mp3' || ext === 'wav') return true;
    if (mime === 'audio/mpeg' || mime === 'audio/mp3') return true;
    if (mime === 'audio/wav' || mime === 'audio/x-wav') return true;
    return false;
  }

  private _coverAllowed(file: Express.Multer.File): boolean {
    const name = (file.originalname ?? '').toLowerCase();
    const mime = (file.mimetype ?? '').toLowerCase();
    const ext = name.split('.').pop() ?? '';

    // PASO 2 allowed formats: jpg,png,webp
    if (ext === 'jpg' || ext === 'jpeg' || ext === 'png' || ext === 'webp') return true;
    if (mime === 'image/jpeg' || mime === 'image/png' || mime === 'image/webp') return true;
    return false;
  }

  private async _resolveDjProfileForUpload(params: {
    user: { sub: string; role: Role };
    djId?: string;
  }) {
    if (params.user.role === Role.DJ) {
      const dj = await this.prisma.djProfile.findUnique({ where: { userId: params.user.sub } });
      if (!dj) throw new ForbiddenException('DJ profile missing');
      if ((dj.status as any) === DjStatus.BLOCKED) throw new ForbiddenException('DJ is blocked');
      if ((dj.status as any) === DjStatus.PENDING) {
        throw new ForbiddenException('DJ pending approval');
      }
      return dj;
    }

    if (params.user.role === Role.ADMIN) {
      if (!this._allowAdminUpload()) {
        throw new ForbiddenException('ADMIN upload disabled (set ALLOW_ADMIN_UPLOAD=true for local dev)');
      }

      if (params.djId && params.djId.trim().length > 0) {
        const dj = await this.prisma.djProfile.findUnique({ where: { id: params.djId.trim() } });
        if (!dj) throw new BadRequestException('Invalid djId');
        if ((dj.status as any) !== DjStatus.APPROVED) {
          throw new BadRequestException('djId must be APPROVED');
        }
        return dj;
      }

      // If no djId provided, create/attach an admin DJ profile for local uploads.
      const existing = await this.prisma.djProfile.findUnique({ where: { userId: params.user.sub } });
      if (existing) return existing;

      const now = new Date();
      return this.prisma.djProfile.create({
        data: {
          userId: params.user.sub,
          displayName: 'Admin Uploads',
          bio: 'Local admin uploads',
          location: 'Local',
          genres: ['mixed'],
          status: DjStatus.APPROVED as any,
          createdAt: now,
          updatedAt: now,
        },
      });
    }

    throw new ForbiddenException('DJ only');
  }

  async upload(params: {
    user: { sub: string; role: Role };
    title: string;
    djId?: string;
    description?: string;
    genre?: string;
    isClean?: boolean;
    audio?: Express.Multer.File;
    cover?: Express.Multer.File;
  }) {
    const title = params.title.trim();
    if (!title) throw new BadRequestException('title required');
    if (!params.audio) throw new BadRequestException('audio file required');
    if (!params.cover) throw new BadRequestException('cover file required');

    const dj = await this._resolveDjProfileForUpload({ user: params.user, djId: params.djId });

    if (!this._audioAllowed(params.audio)) {
      throw new BadRequestException('audio must be mp3 or wav');
    }
    if (!this._coverAllowed(params.cover)) {
      throw new BadRequestException('cover must be jpg, png, or webp');
    }

    let audioUp;
    let coverUp;
    try {
      [audioUp, coverUp] = await Promise.all([
        this.cloudinary.uploadBuffer({
          buffer: params.audio.buffer,
          filename: params.audio.originalname,
          folder: 'zylofm/mixes',
          resourceType: 'video',
          contentType: params.audio.mimetype,
        }),
        this.cloudinary.uploadBuffer({
          buffer: params.cover.buffer,
          filename: params.cover.originalname,
          folder: 'zylofm/mixes',
          resourceType: 'image',
          contentType: params.cover.mimetype,
        }),
      ]);
    } catch (e: any) {
      const msg = typeof e?.message === 'string' ? e.message : 'Cloudinary upload failed';
      throw new BadRequestException(msg);
    }

    const mix = await this.prisma.mix.create({
      data: {
        djId: dj.id,
        title,
        description: (params.description ?? '').trim(),
        genre: (params.genre ?? '').trim(),
        audioUrl: audioUp.secureUrl,
        coverUrl: coverUp.secureUrl,
        status: MixStatus.PENDING as any,
        isClean: params.isClean ?? true,
      },
      include: { dj: { select: { id: true, displayName: true } } },
    });

    return this._toApiMix(mix);
  }

  async listPending() {
    const mixes = await this.prisma.mix.findMany({
      where: { status: MixStatus.PENDING as any },
      orderBy: { createdAt: 'desc' },
      include: { dj: { select: { id: true, displayName: true } } },
    });
    return mixes.map((m) => this._toApiMix(m));
  }

  async adminSetStatus(id: string, status: 'approved' | 'rejected') {
    const mix = await this.prisma.mix.findUnique({ where: { id }, include: { dj: { select: { id: true, displayName: true } } } });
    if (!mix) throw new NotFoundException('Mix not found');

    const next = status === 'approved' ? MixStatus.APPROVED : MixStatus.REJECTED;
    const updated = await this.prisma.mix.update({
      where: { id },
      data: { status: next as any },
      include: { dj: { select: { id: true, displayName: true } } },
    });
    return this._toApiMix(updated);
  }

  async listPublicApproved() {
    const mixes = await this.prisma.mix.findMany({
      where: { status: MixStatus.APPROVED as any },
      orderBy: { createdAt: 'desc' },
      include: { dj: { select: { id: true, displayName: true } } },
    });
    return mixes.map((m) => this._toApiMix(m));
  }

  async listForDj(params: { djId: string; viewer: Viewer }) {
    const dj = await this.prisma.djProfile.findUnique({ where: { id: params.djId } });
    if (!dj) throw new NotFoundException('DJ not found');

    const viewerIsOwner =
      params.viewer?.role === Role.DJ &&
      (await this.prisma.djProfile.findUnique({ where: { userId: params.viewer.sub } }))?.id === dj.id;

    const viewerIsAdmin = params.viewer?.role === Role.ADMIN;
    const canSeeAll = viewerIsOwner || viewerIsAdmin;

    const mixes = await this.prisma.mix.findMany({
      where: {
        djId: dj.id,
        ...(canSeeAll ? {} : { status: MixStatus.APPROVED as any }),
      },
      orderBy: { createdAt: 'desc' },
      include: { dj: { select: { id: true, displayName: true } } },
    });

    return mixes.map((m) => this._toApiMix(m));
  }

  // Compatibility for old admin routes.
  adminApprove(id: string) {
    return this.adminSetStatus(id, 'approved');
  }

  adminReject(id: string) {
    return this.adminSetStatus(id, 'rejected');
  }

  adminTakedown(id: string) {
    return this.adminSetStatus(id, 'rejected');
  }

  private _toApiMix(mix: any) {
    return {
      id: mix.id,
      djId: mix.djId,
      djName: mix.dj?.displayName ?? undefined,
      title: mix.title,
      description: mix.description,
      genre: mix.genre,
      audioUrl: mix.audioUrl,
      coverUrl: mix.coverUrl,
      status: (mix.status as string).toLowerCase(),
      isClean: mix.isClean,
      createdAt: mix.createdAt,
    };
  }
}
