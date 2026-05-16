import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class StartSessionDto {
  @ApiProperty({ required: false, description: 'Scenario id; omit for free talk' })
  @IsOptional() @IsUUID()
  scenarioId?: string;

  @ApiProperty()
  @IsUUID()
  personaId!: string;

  @ApiProperty({ enum: ['chat', 'face'] })
  @IsIn(['chat', 'face'])
  mode!: 'chat' | 'face';
}

export class SendMessageDto {
  @ApiProperty()
  @IsString() @MinLength(1) @MaxLength(5000)
  content!: string;

  @ApiProperty({ required: false })
  @IsOptional() @IsString()
  audioUrl?: string;
}

export class EndSessionDto {
  @ApiProperty({ required: false, default: 'completed', enum: ['completed', 'abandoned'] })
  @IsOptional() @IsIn(['completed', 'abandoned'])
  status?: 'completed' | 'abandoned';
}

export class MessageDto {
  @ApiProperty() id!: string;
  @ApiProperty() role!: 'user' | 'assistant';
  @ApiProperty() content!: string;
  @ApiProperty() sequence!: number;
  @ApiProperty() createdAt!: Date;
}

export class SessionDto {
  @ApiProperty() id!: string;
  @ApiProperty() scenarioId!: string | null;
  @ApiProperty() personaId!: string;
  @ApiProperty() mode!: 'chat' | 'face';
  @ApiProperty() status!: 'active' | 'completed' | 'abandoned';
  @ApiProperty() startedAt!: Date;
  @ApiProperty() endedAt!: Date | null;
  @ApiProperty() turnCount!: number;
  @ApiProperty() wordCount!: number;
  @ApiProperty() xpEarned!: number;
}

export class SendMessageResponseDto {
  @ApiProperty() userMessage!: MessageDto;
  @ApiProperty() assistantMessage!: MessageDto;
  @ApiProperty() turnCount!: number;
}
