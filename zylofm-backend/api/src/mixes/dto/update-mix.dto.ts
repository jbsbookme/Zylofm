import { IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * UpdateMixDto (PASO 8.4)
 *
 * Metadata-only updates; status changes happen via /publish or admin takedown.
 */
export class UpdateMixDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  description?: string;
}
