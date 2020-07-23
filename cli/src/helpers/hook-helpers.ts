import { getTemplateDirectory } from './template-helpers';
import { resolve } from 'path';
import { tryStatFile } from './file-helpers';
import getDebug from 'debug';

const debug = getDebug('nmbl:helpers:hooks');

export type HookCallback<HookArgs> = (args: HookArgs) => Promise<void>;
export type HookImport<HookArgs> = { default: HookCallback<HookArgs> };

export const getHooksDirectory = () => './hooks';

export const getHookFile = (projectRoot: string, hookName: string) => {
  let hookFile = resolve(
    projectRoot,
    getTemplateDirectory(),
    getHooksDirectory(),
    `${hookName}.ts`
  );

  if (!tryStatFile(hookFile)) {
    hookFile = resolve(
      projectRoot,
      getTemplateDirectory(),
      getHooksDirectory(),
      `${hookName}.ts`
    );
  }

  debug('getHookFile: %o', { hookFile, projectRoot, hookName });

  return hookFile;
};

export const hasHook = (projectRoot: string, hookName: string) => {
  const hookFile = getHookFile(projectRoot, hookName);
  const hasHook = !!tryStatFile(hookFile);

  debug('hasHook: %o', hasHook, hookFile, projectRoot, hookName);

  return hasHook;
};

export const loadHook = async <HookArgs>(
  projectRoot: string,
  hookName: string
) => {
  let hook = null;

  if (hasHook(projectRoot, hookName)) {
    const hookFile = getHookFile(projectRoot, hookName);
    const hookImport = (await import(hookFile)) as HookImport<HookArgs>;

    hook = hookImport?.default ?? null;
  }

  debug('loadHook: %o', {
    hookLoaded: !!hook,
    projectRoot,
    hookName,
  });

  return hook;
};

export const doHook = async <HookArgs>(
  projectRoot: string,
  hookName: string,
  args: HookArgs
) => {
  const hook = await loadHook<HookArgs>(projectRoot, hookName);

  hook && (await hook(args));
};
