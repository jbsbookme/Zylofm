import { Transform } from 'class-transformer';
import { IsArray, IsBoolean, IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class CreateAssistantLibraryItemDto {
  @IsString()
  @MaxLength(120)
  title!: string;

  @IsString()
  @IsUrl({ require_tld: false })
  audioUrl!: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @MaxLength(40, { each: true })
  @Transform(({ value }) => {
    if (!Array.isArray(value)) return value;
    return value
      .map((v) => (typeof v === 'string' ? v.trim().toLowerCase() : v))
      .filter((v) => typeof v === 'string' && v.length > 0);
  })
  keywords?: string[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
