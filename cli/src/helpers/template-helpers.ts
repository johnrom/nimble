import { linkSubmodule } from './git-helpers';
import { CLIError } from '@oclif/errors';
import getDebug from 'debug';

const debug = getDebug('nmbl:helpers:template');

export const isValidTemplate = (value: string): value is string => {
  const isValid =
    value?.replace(/[^A-Za-z0-9-_./#]/, '') === value &&
    /^(\.\.?\/)?.+\/.+$/.test(value);

  debug('isValidTemplate: %o', { value, isValid });

  return isValid;
};

export const getTemplateDirectory = () => './_nmbl/template';

export const fetchTemplate = async (
  templateName: string,
  rootDirectory: string
) => {
  if (!isValidTemplate(templateName)) {
    throw new CLIError('fetchTemplate called without a valid template name.');
  }

  const templatePath = './_nmbl/template';

  debug(`fetchTemplate: %O`, {
    templateName,
    rootDirectory,
    templatePath,
  });

  await linkSubmodule(templateName, rootDirectory, templatePath);
};
