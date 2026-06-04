# PS C:\project\vLearn2\backend> npm run db:seed    > backend@0.0.1 db:seed > ts-n

Session: `ec7e9529-1399-4642-b1c1-753f53834cc7`
Saved: 2026-06-04T13:19:10.120Z

## User

PS C:\project\vLearn2\backend> npm run db:seed   

> backend@0.0.1 db:seed
> ts-node ./src/database/seeds/run-seeds.ts

C:\project\vLearn2\backend\node_modules\ts-node\src\index.ts:859
    return new TSError(diagnosticText, diagnosticCodes, diagnostics);
           ^
TSError: ⨯ Unable to compile TypeScript:
src/database/seeds/seeds/app-config.seed.ts:541:7 - error TS2322: Type '"home" | "evaluation" | "progress" | "conversation" | "scenarios" | "settings" | "prompts" | "system" | "scenario_detail"' is not assignable to type 'AppConfigCategory'.
  Type '"scenario_detail"' is not assignable to type 'AppConfigCategory'.

541       existing.category = c.category;
          ~~~~~~~~~~~~~~~~~
src/database/seeds/seeds/app-config.seed.ts:548:14 - error TS2769: No overload matches this call.
  Overload 1 of 3, '(entityLikeArray: DeepPartial<AppConfigEntity>[]): AppConfigEntity[]', gave the following error.
    Object literal may only specify known properties, but 'key' does not exist in type 'DeepPartial<AppConfigEntity>[]'. Did you mean to write 'keys'?
  Overload 2 of 3, '(entityLike: DeepPartial<AppConfigEntity>): AppConfigEntity', gave the following error.
    Type '"home" | "evaluation" | "progress" | "conversation" | "scenarios" | "settings" | "prompts" | "system" | "scenario_detail"' is not assignable to type '"home" | "evaluation" | "progress" | "conversation" | "scenarios" | "settings" | "prompts" | "system" | undefined'.
      Type '"scenario_detail"' is not assignable to type '"home" | "evaluation" | "progress" | "conversation" | "scenarios" | "settings" | "prompts" | "system" | undefined'.

548         repo.create({
                 ~~~~~~

  src/database/entities/app-config.entity.ts:39:3
    39   category!: AppConfigCategory;
         ~~~~~~~~
    The expected type comes from property 'category' which is declared here on type 'DeepPartial<AppConfigEntity>'

    at createTSError (C:\project\vLearn2\backend\node_modules\ts-node\src\index.ts:859:12)
    at reportTSError (C:\project\vLearn2\backend\node_modules\ts-node\src\index.ts:863:19)
    at getOutput (C:\project\vLearn2\backend\node_modules\ts-node\src\index.ts:1077:36)
    at Object.compile (C:\project\vLearn2\backend\node_modules\ts-node\src\index.ts:1433:41)
    at Module.m._compile (C:\project\vLearn2\backend\node_modules\ts-node\src\index.ts:1617:30)
    at Module._extensions..js (node:internal/modules/cjs/loader:1422:10)
    at Object.require.extensions.<computed> [as .ts] (C:\project\vLearn2\backend\node_modules\ts-node\src\index.ts:1621:12)
    at Module.load (node:internal/modules/cjs/loader:1203:32)
    at Function.Module._load (node:internal/modules/cjs/loader:1019:12)
    at Module.require (node:internal/modules/cjs/loader:1231:19) {
  diagnosticCodes: [ 2322, 2769 ]
}

## Assistant

`AppConfigCategory` in the entity needs `'scenario_detail'` added to it:

## Assistant

Run `npm run db:seed` again — it will work now.
