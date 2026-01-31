import 'dotenv/config';

import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  // PASO 8.5: In-memory mode should run out-of-the-box.
  // If a JWT_SECRET is provided, enforce a minimum length.
  // If none is provided, use a dev-only default.
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.trim().length === 0) {
    process.env.JWT_SECRET = 'dev-only-jwt-secret-change-me-please';
  }
  if (process.env.JWT_SECRET.trim().length < 16) {
    throw new Error('JWT_SECRET is too short. Use at least 16 characters.');
  }

  const app = await NestFactory.create(AppModule);

  // CORS
  // - Mobile apps (iOS/Android) typically don't send an Origin header.
  // - Browsers (Admin Dashboard) do, so we restrict in production via env.
  const rawCorsOrigins = (process.env.CORS_ORIGINS ?? '').trim();
  const allowedOrigins = rawCorsOrigins
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  if (allowedOrigins.length === 0) {
    // Local/dev default: allow all.
    app.enableCors();
  } else {
    app.enableCors({
      origin: (origin, cb) => {
        if (!origin) return cb(null, true);
        if (allowedOrigins.includes(origin)) return cb(null, true);
        return cb(new Error('CORS: origin not allowed'));
      },
      methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['content-type', 'authorization'],
      credentials: false,
    });
  }

  // PASO 8.2: Validate incoming DTOs.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
