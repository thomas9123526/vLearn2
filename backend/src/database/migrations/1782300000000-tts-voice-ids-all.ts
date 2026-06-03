import { MigrationInterface, QueryRunner } from 'typeorm';

const ALL_VOICES = [
  'en_VCTK-amy', 'en_VCTK-james',
  'en_VCTK-p227-m', 'en_VCTK-p228-f', 'en_VCTK-p229-f', 'en_VCTK-p230-f',
  'en_VCTK-p231-m', 'en_VCTK-p232-m', 'en_VCTK-p233-f', 'en_VCTK-p234-f',
  'en_VCTK-p235-m', 'en_VCTK-p236-f', 'en_VCTK-p237-m', 'en_VCTK-p238-f',
  'en_VCTK-p239-f', 'en_VCTK-p240-f', 'en_VCTK-p241-m', 'en_VCTK-p242-f',
  'en_VCTK-p243-m', 'en_VCTK-p244-f', 'en_VCTK-p245-m', 'en_VCTK-p246-m',
  'en_VCTK-p247-m', 'en_VCTK-p248-f', 'en_VCTK-p249-f', 'en_VCTK-p250-m',
  'en_VCTK-p251-f', 'en_VCTK-p252-m', 'en_VCTK-p253-m', 'en_VCTK-p254-m',
  'en_VCTK-p255-m', 'en_VCTK-p256-m', 'en_VCTK-p257-f', 'en_VCTK-p258-m',
  'en_VCTK-p259-m', 'en_VCTK-p260-m', 'en_VCTK-p261-f', 'en_VCTK-p262-m',
  'en_VCTK-p263-m', 'en_VCTK-p264-m', 'en_VCTK-p265-f', 'en_VCTK-p266-f',
  'en_VCTK-p267-m', 'en_VCTK-p268-f', 'en_VCTK-p269-f', 'en_VCTK-p270-m',
  'en_VCTK-p271-m', 'en_VCTK-p272-m', 'en_VCTK-p273-m', 'en_VCTK-p274-m',
  'en_VCTK-p275-m', 'en_VCTK-p276-f', 'en_VCTK-p277-m', 'en_VCTK-p278-f',
  'en_VCTK-p279-f', 'en_VCTK-p280-f', 'en_VCTK-p281-m', 'en_VCTK-p282-f',
  'en_VCTK-p283-m', 'en_VCTK-p284-m', 'en_VCTK-p285-m', 'en_VCTK-p286-m',
  'en_VCTK-p287-f', 'en_VCTK-p288-f', 'en_VCTK-p292-m', 'en_VCTK-p293-m',
  'en_VCTK-p294-f', 'en_VCTK-p295-f', 'en_VCTK-p297-m', 'en_VCTK-p298-m',
  'en_VCTK-p299-m', 'en_VCTK-p300-f', 'en_VCTK-p301-f', 'en_VCTK-p302-m',
  'en_VCTK-p303-f', 'en_VCTK-p304-m', 'en_VCTK-p305-f', 'en_VCTK-p306-f',
  'en_VCTK-p307-m', 'en_VCTK-p308-f', 'en_VCTK-p310-f', 'en_VCTK-p311-m',
  'en_VCTK-p312-m', 'en_VCTK-p313-m', 'en_VCTK-p314-m', 'en_VCTK-p316-m',
  'en_VCTK-p317-m', 'en_VCTK-p318-f', 'en_VCTK-p323-m', 'en_VCTK-p326-m',
  'en_VCTK-p329-f', 'en_VCTK-p330-m', 'en_VCTK-p333-m', 'en_VCTK-p334-m',
  'en_VCTK-p335-m', 'en_VCTK-p336-m', 'en_VCTK-p339-f', 'en_VCTK-p340-m',
  'en_VCTK-p341-m', 'en_VCTK-p343-f', 'en_VCTK-p345-m', 'en_VCTK-p347-f',
  'en_VCTK-p351-f', 'en_VCTK-p360-m', 'en_VCTK-p361-m', 'en_VCTK-p362-m',
  'en_VCTK-p363-m', 'en_VCTK-p364-m', 'en_VCTK-p374-f',
];

export class TtsVoiceIdsAll1782300000000 implements MigrationInterface {
  name = 'TtsVoiceIdsAll1782300000000';

  async up(qr: QueryRunner): Promise<void> {
    const json = JSON.stringify(ALL_VOICES);
    await qr.query(`
      UPDATE vl_app_config
      SET value        = $1::jsonb,
          default_value = $1::jsonb,
          value_type   = 'array'
      WHERE key = 'tts.voice_ids'
    `, [json]);

    // Insert if the row didn't exist yet
    await qr.query(`
      INSERT INTO vl_app_config (key, value, default_value, value_type, category, description, is_visible_to_app)
      SELECT 'tts.voice_ids', $1::jsonb, $1::jsonb, 'array', 'system',
             'Available TTS voice IDs shown in the admin tutor edit dropdown.',
             false
      WHERE NOT EXISTS (SELECT 1 FROM vl_app_config WHERE key = 'tts.voice_ids')
    `, [json]);
  }

  async down(qr: QueryRunner): Promise<void> {
    await qr.query(`
      UPDATE vl_app_config
      SET value         = '["en_VCTK-amy","en_VCTK-james"]'::jsonb,
          default_value = '["en_VCTK-amy","en_VCTK-james"]'::jsonb
      WHERE key = 'tts.voice_ids'
    `);
  }
}
