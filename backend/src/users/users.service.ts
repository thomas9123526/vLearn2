import { BadRequestException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { UserEntity } from '../database/entities/user.entity';
import type { UpdateProfileDto, UserProfileDto } from './dto/user.dto';

const BCRYPT_ROUNDS = 10;

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
    if (dto.displayName !== undefined) user.name = dto.displayName;
    if (dto.avatarEmoji !== undefined) user.avatar_emoji = dto.avatarEmoji;
    if (dto.gender !== undefined) user.gender = dto.gender;
    if (dto.uiLanguage !== undefined) user.ui_language = dto.uiLanguage;
    if (dto.activeTheme !== undefined) user.active_theme = dto.activeTheme;
    if (dto.activePersonaId !== undefined) user.active_persona_id = dto.activePersonaId;
    if (dto.onboardingDone !== undefined) user.onboarding_done = dto.onboardingDone;

    // Password change requires the current password as proof-of-control,
    // even when the caller already has a valid access token (stolen-device
    // protection). The password_hash column is `select: false`, so we have
    // to re-query with explicit selection.
    if (dto.newPassword !== undefined) {
      if (!dto.currentPassword) {
        throw new BadRequestException({ i18nKey: 'user.current_password_required' });
      }
      const withHash = await this.users.findOne({
        where: { id },
        select: ['id', 'password_hash'],
      });
      if (!withHash) throw new NotFoundException({ i18nKey: 'user.not_found' });
      const ok = await bcrypt.compare(dto.currentPassword, withHash.password_hash);
      if (!ok) throw new UnauthorizedException({ i18nKey: 'user.current_password_wrong' });
      user.password_hash = await bcrypt.hash(dto.newPassword, BCRYPT_ROUNDS);
    }

    await this.users.save(user);
    return this.toProfile(user);
  }

  private toProfile(u: UserEntity): UserProfileDto {
    return {
      id: u.id,
      email: u.email,
      displayName: u.name,
      avatarEmoji: u.avatar_emoji,
      gender: u.gender,
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
