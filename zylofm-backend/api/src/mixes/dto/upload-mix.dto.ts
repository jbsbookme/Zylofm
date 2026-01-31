import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

/**
 * UploadMixDto (PASO 1)
 *
 * Metadata for uploading a mix (files are sent as multipart form-data).
 */
export class UploadMixDto {
  @IsString()
  @MaxLength(120)
  title!: string;

  // Dev/admin helper: allows an ADMIN (when enabled) to attribute the upload to a specific DJ profile.
  @IsOptional()
  @IsUUID()
  djId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  genre?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === true || value === false) return value;
    if (typeof value === 'string') {
      const v = value.trim().toLowerCase();
      if (['1', 'true', 'yes', 'y', 'on'].includes(v)) return true;
      if (['0', 'false', 'no', 'n', 'off'].includes(v)) return false;
    }
    return value;
  })
  @IsBoolean()
  isClean?: boolean;
}
