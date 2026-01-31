import { IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * CreateMixDto (PASO 8.4)
 *
 * Legacy DTO (metadata-only).
 */
export class CreateMixDto {
  @IsString()
  @MaxLength(120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  description?: string;
}
