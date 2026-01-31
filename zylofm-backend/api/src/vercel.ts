import type { VercelRequest, VercelResponse } from '@vercel/node';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { ExpressAdapter } from '@nestjs/platform-express';
import express from 'express';

let cachedHandler: ((req: VercelRequest, res: VercelResponse) => void) | null = null;

function configureCors(app: any) {
  const rawCorsOrigins = (process.env.CORS_ORIGINS ?? '').trim();
  const allowedOrigins = rawCorsOrigins
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  if (allowedOrigins.length === 0) {
    app.enableCors();
    return;
  }

  app.enableCors({
    origin: (origin: string | undefined, cb: (err: Error | null, ok?: boolean) => void) => {
      if (!origin) return cb(null, true);
      if (allowedOrigins.includes(origin)) return cb(null, true);
      return cb(new Error('CORS: origin not allowed'));
    },
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['content-type', 'authorization'],
    credentials: false,
  });
}

function ensureJwtSecret() {
  const raw = (process.env.JWT_SECRET ?? '').trim();
  const isProd = process.env.NODE_ENV === 'production';

  if (!raw) {
    if (isProd) {
      throw new Error('Missing JWT_SECRET (required in production).');
    }
    process.env.JWT_SECRET = 'dev-only-jwt-secret-change-me-please';
    return;
  }

  if (raw.length < 16) {
    throw new Error('JWT_SECRET is too short. Use at least 16 characters.');
  }
}

async function getHandler() {
  if (cachedHandler) return cachedHandler;

  ensureJwtSecret();

  // Lazy-load the Nest module so import-time failures are catchable
  // by the handler try/catch (instead of crashing the whole function).
  const { AppModule } = await import('./app.module.js');

  const server = express();
  const nestApp = await NestFactory.create(AppModule, new ExpressAdapter(server), {
    // keep logs minimal in serverless
    logger: ['error', 'warn', 'log'],
  });

  configureCors(nestApp);

  nestApp.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  await nestApp.init();

  cachedHandler = (req: VercelRequest, res: VercelResponse) => {
    // Express can handle VercelRequest/VercelResponse (they extend req/res)
    server(req as any, res as any);
  };

  return cachedHandler;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    const h = await getHandler();
    return h(req, res);
  } catch (e) {
    // Ensure we get *some* actionable signal in Vercel logs.
    // Do not include stack traces in responses (can leak internals).
    // eslint-disable-next-line no-console
    console.error('Vercel function bootstrap failed:', e);

    const message =
      e instanceof Error
        ? e.message
        : typeof e === 'string'
          ? e
          : 'Unknown error';

    res.status(500).json({
      error: 'BOOTSTRAP_FAILED',
      message,
    });
  }
}
