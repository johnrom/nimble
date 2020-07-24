import { BaseHookArgs, HookCallback } from './../types/hooks';
import { getAbsoluteTemplatePath } from './template-helpers';
import { resolve } from 'path';
import { tryStatFile } from './file-helpers';
import getDebug from 'debug';

const debug = getDebug('nmbl:helpers:hooks');

type HookImport<HookArgs, ReturnArgs> = {
  default: HookCallback<HookArgs, ReturnArgs>;
};

export const getHooksDirectory = () => './hooks';

export const getHookFile = async (projectRoot: string, hookName: string) => {
  const templatePath = getAbsoluteTemplatePath(projectRoot);
  let hookFile = resolve(templatePath, getHooksDirectory(), `${hookName}.ts`);

  if (!(await tryStatFile(hookFile))) {
    hookFile = resolve(templatePath, getHooksDirectory(), `${hookName}.ts`);
  }

  debug('getHookFile: %o', { hookFile, projectRoot, hookName });

  return hookFile;
};

export const hasHook = async (projectRoot: string, hookName: string) => {
  const hookFile = await getHookFile(projectRoot, hookName);
  const hasHook = !!(await tryStatFile(hookFile));

  debug('hasHook: %o', hasHook, hookFile, projectRoot, hookName);

  return hasHook;
};

export const loadHook = async <HookArgs, ReturnArgs = void>(
  projectRoot: string,
  hookName: string
) => {
  let hook = null;

  if (await hasHook(projectRoot, hookName)) {
    const hookFile = await getHookFile(projectRoot, hookName);
    const hookImport = (await import(hookFile)) as HookImport<
      HookArgs,
      ReturnArgs
    >;

    hook = hookImport?.default ?? null;
  }

  debug('loadHook: %o', {
    hookLoaded: !!hook,
    projectRoot,
    hookName,
  });

  return hook;
};

export const doHook = async <HookArgs, ReturnArgs = void>(
  projectRoot: string,
  hookName: string,
  args: HookArgs
) => {
  const hook = await loadHook<HookArgs, ReturnArgs>(projectRoot, hookName);

  if (hook) {
    return hook(args);
  }

  return Promise.resolve(null);
};

export const getBaseHookArgs = (
  projectName: string,
  path: string
): BaseHookArgs => ({
  projectName,
  templateRoot: getAbsoluteTemplatePath(path),
  projectRoot: resolve(path),
});
