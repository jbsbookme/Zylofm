import { Transform } from 'class-transformer';
import { IsArray, IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateAssistantLibraryItemDto {
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (Array.isArray(value)) return value;
    if (typeof value === 'string') {
      const v = value.trim();
      if (!v) return [];
      return v
        .split(/[\s,]+/)
        .map((t) => t.trim())
        .filter(Boolean)
        .slice(0, 40);
    }
    return value;
  })
  @IsArray()
  @IsString({ each: true })
  keywords?: string[];

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
