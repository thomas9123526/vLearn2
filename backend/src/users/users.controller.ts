import {
  Body,
  Controller,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../auth/strategies/jwt.strategy';
import { UsersService } from './users.service';
import { UpdateProfileDto, UserProfileDto } from './dto/user.dto';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get the current user profile' })
  @ApiOkResponse({ type: UserProfileDto })
  profile(@CurrentUser() user: JwtPayload): Promise<UserProfileDto> {
    return this.users.profileFor(user.sub);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update the current user profile' })
  @ApiOkResponse({ type: UserProfileDto })
  update(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateProfileDto,
  ): Promise<UserProfileDto> {
    return this.users.updateProfile(user.sub, dto);
  }
}
