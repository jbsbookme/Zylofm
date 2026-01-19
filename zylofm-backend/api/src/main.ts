import 'dotenv/config';

import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  // PASO 8.2: Auth requires a JWT secret.
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.trim().length < 16) {
    // Keep it explicit so the app never runs with a weak/empty secret by accident.
    throw new Error(
      'JWT_SECRET is missing or too short. Set it in .env (e.g. a long random string).',
    );
  }

  const app = await NestFactory.create(AppModule);

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
