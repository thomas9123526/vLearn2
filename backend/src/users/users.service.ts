import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserEntity } from '../database/entities/user.entity';
import type { UpdateProfileDto, UserProfileDto } from './dto/user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
  ) {}

  async findById(id: string): Promise<UserEntity> {
    const user = await this.users.findOne({ where: { id } });
    if (!user) throw new NotFoundException({ i18nKey: 'user.not_found' });
    return user;
  }

  async profileFor(id: string): Promise<UserProfileDto> {
    return this.toProfile(await this.findById(id));
  }

  async updateProfile(id: string, dto: UpdateProfileDto): Promise<UserProfileDto> {
    const user = await this.findById(id);
    if (dto.displayName !== undefined) user.display_name = dto.displayName;
    if (dto.avatarEmoji !== undefined) user.avatar_emoji = dto.avatarEmoji;
    if (dto.uiLanguage !== undefined) user.ui_language = dto.uiLanguage;
    if (dto.activeTheme !== undefined) user.active_theme = dto.activeTheme;
    if (dto.activePersonaId !== undefined) user.active_persona_id = dto.activePersonaId;
    if (dto.onboardingDone !== undefined) user.onboarding_done = dto.onboardingDone;
    await this.users.save(user);
    return this.toProfile(user);
  }

  private toProfile(u: UserEntity): UserProfileDto {
    return {
      id: u.id,
      email: u.email,
      displayName: u.display_name,
      avatarEmoji: u.avatar_emoji,
      nativeLanguage: u.native_language,
      uiLanguage: u.ui_language,
      currentLevel: u.current_level,
      xpTotal: u.xp_total,
      streakDays: u.streak_days,
      activePersonaId: u.active_persona_id,
      activeTheme: u.active_theme,
      onboardingDone: u.onboarding_done,
      role: u.role,
      status: u.status,
    };
  }
}
