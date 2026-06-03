import { Module, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AI_PROVIDER, AiProvider } from './ai-provider.interface';
import { AnthropicProvider } from './providers/anthropic.provider';
import { OpenAICompatibleProvider } from './providers/openai-compatible.provider';
import { PromptBuilderService } from './prompt-builder.service';
import { ConversationOrchestrator } from './conversation.orchestrator';
import { PromptTemplateEntity } from '../database/entities/prompt-template.entity';
import { AppConfigEntity } from '../database/entities/app-config.entity';

@Module({
  imports: [TypeOrmModule.forFeature([PromptTemplateEntity, AppConfigEntity])],
  providers: [
    AnthropicProvider,
    OpenAICompatibleProvider,
    PromptBuilderService,
    ConversationOrchestrator,
    {
      provide: AI_PROVIDER,
      inject: [ConfigService, AnthropicProvider, OpenAICompatibleProvider],
      useFactory: (
        config: ConfigService,
        anthropic: AnthropicProvider,
        openai: OpenAICompatibleProvider,
      ): AiProvider => {
        const kind = config.get<string>('AI_PROVIDER') ?? 'anthropic';
        const logger = new Logger('AiProviderFactory');
        switch (kind) {
          case 'anthropic':
            logger.log('Using AnthropicProvider');
            return anthropic;
          case 'openai-compatible':
          case 'ollama':
          case 'groq':
          case 'together':
            logger.log(`Using OpenAICompatibleProvider (label=${openai.name})`);
            return openai;
          default:
            logger.warn(
              `Unknown AI_PROVIDER='${kind}', falling back to anthropic`,
            );
            return anthropic;
        }
      },
    },
  ],
  exports: [AI_PROVIDER, ConversationOrchestrator, PromptBuilderService],
})
export class AiModule {}
