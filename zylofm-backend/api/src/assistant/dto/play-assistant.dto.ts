import { IsString, MaxLength } from 'class-validator';

export class PlayAssistantDto {
  @IsString()
  @MaxLength(200)
  query!: string;
}
