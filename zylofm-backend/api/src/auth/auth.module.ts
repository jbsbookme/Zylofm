import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { RolesGuard } from '../common/roles.guard';
import { AdminBootstrapService } from './admin-bootstrap.service';

/**
 * AuthModule (PASO 8.2)
 *
 * JWT secret is read from process.env.JWT_SECRET.
 */
@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      useFactory: () => ({
        secret: process.env.JWT_SECRET,
        signOptions: {
          // Keep it simple and safe; can be tuned later.
          expiresIn: '7d',
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, RolesGuard, AdminBootstrapService],
  exports: [AuthService, RolesGuard],
})
export class AuthModule {}
