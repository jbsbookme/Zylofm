import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/**
 * CreateDjProfileDto (PASO 9.1)
 *
 * Minimal profile data to onboard a DJ.
 */
export class CreateDjProfileDto {
  @IsString()
  @MaxLength(60)
  displayName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(600)
  bio?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  location?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(12)
  @IsString({ each: true })
  @MaxLength(32, { each: true })
  genres?: string[];
}
