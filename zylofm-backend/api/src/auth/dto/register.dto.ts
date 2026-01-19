import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

/**
 * RegisterDto
 *
 * Keep it intentionally minimal for PASO 8.2.
 */
export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  // Optional: create a DJ profile right away.
  @IsOptional()
  @IsString()
  displayName?: string;
}
