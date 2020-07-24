export interface BaseHookArgs {
  projectName: string;
  templateRoot: string;
  projectRoot: string;
}

export type CreateHookArgs<TBaseArgs = BaseHookArgs> = TBaseArgs & {};
export type CreateTestsHookArgs<TBaseArgs = BaseHookArgs> = TBaseArgs & {};

export type HookCallback<HookArgs, ReturnArgs = void> = (
  args: HookArgs
) => Promise<ReturnArgs>;
