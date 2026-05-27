import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { UserEntity } from '../database/entities/user.entity';
import { UserInfoEntity } from '../database/entities/user-info.entity';
import type { UpdateProfileDto, UserProfileDto } from './dto/user.dto';

const BCRYPT_ROUNDS = 10;

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
    @InjectRepository(UserInfoEntity)
    private readonly userInfos: Repository<UserInfoEntity>,
  ) {}

  async findById(id: string): Promise<UserEntity> {
    const user = await this.users.findOne({ where: { id } });
    if (!user) throw new NotFoundException({ i18nKey: 'user.not_found' });
    return user;
  }

  async profileFor(id: string): Promise<UserProfileDto> {
    return this.toProfile(await this.findById(id));
  }

  async setAvatar(
    userId: string,
    storageKey: string,
    publicUrl: string,
  ): Promise<UserProfileDto> {
    const user = await this.findById(userId);
    user.info.avatar_storage_key = storageKey;
    user.info.avatar_url = publicUrl;
    await this.userInfos.save(user.info);
    return this.toProfile(user);
  }

  async updateProfile(
    id: string,
    dto: UpdateProfileDto,
  ): Promise<UserProfileDto> {
    const user = await this.findById(id);
    if (dto.displayName !== undefined) user.name = dto.displayName;
    if (dto.gender !== undefined) user.gender = dto.gender;

    if (dto.avatarEmoji !== undefined) user.info.avatar_emoji = dto.avatarEmoji;
    if (dto.uiLanguage !== undefined) user.info.ui_language = dto.uiLanguage;
    if (dto.activeTheme !== undefined) user.info.active_theme = dto.activeTheme;
    if (dto.activePersonaId !== undefined)
      user.info.active_persona_id = dto.activePersonaId;
    if (dto.onboardingDone !== undefined)
      user.info.onboarding_done = dto.onboardingDone;

    // Password change requires current password proof-of-control.
    // password_hash has select:false so we re-query with explicit selection.
    if (dto.newPassword !== undefined) {
      if (!dto.currentPassword) {
        throw new BadRequestException({
          i18nKey: 'user.current_password_required',
        });
      }
      const withHash = await this.users.findOne({
        where: { id },
        select: ['id', 'password_hash'],
      });
      if (!withHash) throw new NotFoundException({ i18nKey: 'user.not_found' });
      const ok = await bcrypt.compare(
        dto.currentPassword,
        withHash.password_hash,
      );
      if (!ok)
        throw new UnauthorizedException({
          i18nKey: 'user.current_password_wrong',
        });
      user.password_hash = await bcrypt.hash(dto.newPassword, BCRYPT_ROUNDS);
    }

    await this.users.save(user);
    return this.toProfile(user);
  }

  private toProfile(u: UserEntity): UserProfileDto {
    return {
      id: u.id,
      email: u.info.email,
      displayName: u.name,
      avatarEmoji: u.info.avatar_emoji,
      avatarUrl: u.info.avatar_url,
      gender: u.gender,
      nativeLanguage: u.info.native_language,
      uiLanguage: u.info.ui_language,
      currentLevel: u.info.current_level,
      xpTotal: u.info.xp_total,
      streakDays: u.info.streak_days,
      activePersonaId: u.info.active_persona_id,
      activeTheme: u.info.active_theme,
      onboardingDone: u.info.onboarding_done,
      role: u.info.role,
      status: u.info.status,
    };
  }
}
