import { tryStatFile } from './file-helpers';
import { linkSubmodule } from './git-helpers';
import { CLIError } from '@oclif/errors';
import getDebug from 'debug';
import { resolve, isAbsolute } from 'path';

const debug = getDebug('nmbl:helpers:template');

export const isValidTemplate = (value: string): value is string => {
  const isValid =
    value?.replace(/[^A-Za-z0-9-_./#]/, '') === value &&
    /^(\.\.?\/)?.+\/.+$/.test(value);

  debug('isValidTemplate: %o', { value, isValid });

  return isValid;
};

export const getTemplatePath = () =>
  process.env.NMBL_TEMPLATE_ROOT ?? './_nmbl/template';

export const getAbsoluteTemplatePath = (rootDirectory: string) => {
  let templatePath = getTemplatePath();

  if (!isAbsolute(templatePath)) {
    templatePath = resolve(rootDirectory, templatePath);
  }

  return templatePath;
};

export const hasExistingTemplate = async (rootDirectory: string) => {
  const templatePath = getAbsoluteTemplatePath(rootDirectory);
  const templateFile = resolve(templatePath, 'template.yml');

  debug('hasExistingTemplate: %O', {
    templateFile,
    rootDirectory,
    templatePath,
  });

  return !!(await tryStatFile(templateFile));
};

export const fetchTemplate = async (
  templateName: string,
  rootDirectory: string
) => {
  if (!isValidTemplate(templateName)) {
    throw new CLIError('fetchTemplate called without a valid template name.');
  }

  const projectPath = resolve(rootDirectory);
  const relativeTemplatePath = getTemplatePath();
  const absoluteTemplatePath = getAbsoluteTemplatePath(rootDirectory);
  const templateExists = await hasExistingTemplate(rootDirectory);
  const templateIsSubdirectory = absoluteTemplatePath.startsWith(projectPath);

  debug(`fetchTemplate: %O`, {
    templateName,
    templateExists,
    templateIsSubdirectory,
    rootDirectory,
    absoluteTemplatePath,
    projectPath,
    relativeTemplatePath,
  });

  if (!templateExists && templateIsSubdirectory) {
    await linkSubmodule(templateName, rootDirectory, relativeTemplatePath);
  }

  if (!hasExistingTemplate(rootDirectory)) {
    if (templateIsSubdirectory) {
      throw new CLIError(
        `Failed to create template at ${relativeTemplatePath}. Is "${templateName}" a valid template?`
      );
    } else {
      throw new CLIError(
        `Template does not exist at ${absoluteTemplatePath} and cannot be created outside of the project root. Check your \`NMBL_TEMPLATE_ROOT\` environment variable.`
      );
    }
  }
};
