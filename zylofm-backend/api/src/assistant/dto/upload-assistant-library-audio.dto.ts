import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class UploadAssistantLibraryAudioDto {
  @IsString()
  @MaxLength(120)
  title!: string;

  // Comma/space separated keywords, e.g. "afro, intro, chill".
  @IsOptional()
  @IsString()
  @MaxLength(400)
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  keywords?: string;

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
  isActive?: boolean;
}
