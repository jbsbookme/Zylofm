import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { MixVisibility } from '@prisma/client';

/**
 * CreateMixDto (PASO 8.4)
 *
 * Creates a mix in DRAFT.
 */
export class CreateMixDto {
  @IsString()
  @MaxLength(120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1200)
  description?: string;

  @IsOptional()
  @IsEnum(MixVisibility)
  visibility?: MixVisibility;
}
