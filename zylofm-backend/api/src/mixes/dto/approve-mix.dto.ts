import { IsIn, IsOptional } from 'class-validator';

export class ApproveMixDto {
  /**
   * Accepts either 'approved' or 'rejected'.
   * Default (if omitted): 'approved'.
   */
  @IsOptional()
  @IsIn(['approved', 'rejected'])
  status?: 'approved' | 'rejected';
}
