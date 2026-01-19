import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Role, User } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';

export type AuthUser = Pick<User, 'id' | 'email' | 'role'>;

/**
 * AuthService (PASO 8.2)
 *
 * - register: creates a User (optional DjProfile if displayName is provided)
 * - login: verifies credentials and returns JWT access token
 *
 * Notes:
 * - No frontend changes.
 * - No refresh tokens for now (kept minimal and clean).
 */
@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(params: {
    email: string;
    password: string;
    displayName?: string;
  }) {
    const email = params.email.trim().toLowerCase();

    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(params.password, 10);

    // PASO 8.3: if the user is creating a DJ profile at signup, mark role as DJ.
    // Otherwise keep LISTENER as the default.
    let finalRole: Role;
    if (params.displayName && params.displayName.trim().length > 0) {
      finalRole = Role.DJ;
    } else {
      finalRole = Role.LISTENER;
    }

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        role: finalRole,
        djProfile: params.displayName
          ? {
              create: {
                displayName: params.displayName,
                bio: '',
                genres: [],
              },
            }
          : undefined,
      },
      select: { id: true, email: true, role: true },
    });

    return this.issueToken(user);
  }

  async login(params: { email: string; password: string }) {
    const email = params.email.trim().toLowerCase();

    const user = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true, email: true, role: true, passwordHash: true },
    });

    if (!user) throw new UnauthorizedException('Invalid credentials');

    const ok = await bcrypt.compare(params.password, user.passwordHash);
    if (!ok) throw new UnauthorizedException('Invalid credentials');

    return this.issueToken({ id: user.id, email: user.email, role: user.role });
  }

  issueToken(user: AuthUser) {
    const payload = { sub: user.id, email: user.email, role: user.role };

    return {
      access_token: this.jwt.sign(payload),
      user,
    };
  }
}
