import { Body, Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { JwtPayload } from './jwt.strategy';

/**
 * AuthController (PASO 8.2)
 *
 * Routes:
 * - POST /auth/register
 * - POST /auth/login
 * - GET  /auth/me
 */
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register({
      email: dto.email,
      password: dto.password,
      displayName: dto.displayName,
    });
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login({ email: dto.email, password: dto.password });
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Request() req: { user: JwtPayload }) {
    // request.user is set by JwtStrategy.validate
    return { user: req.user };
  }
}
