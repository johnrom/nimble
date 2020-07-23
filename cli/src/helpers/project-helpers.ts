import { CLIError } from '@oclif/errors';
import { tryStatFile } from './file-helpers';

export const isProjectNameValid = (value: unknown): value is string =>
  typeof value === 'string' && /^[A-Za-z0-9-_]+$/.test(value);

export const isProjectPathValid = (value: unknown): value is string =>
  typeof value === 'string';

export const throwIfNotValidProject = async () => {
  if (!tryStatFile('_nmbl')) {
    throw new CLIError(
      'Please run this command from the root of a nmbl project. It will contain a `_nmbl` folder.'
    );
  }

  if (!tryStatFile('nmbl.yml')) {
    throw new CLIError(
      'Project does not have a valid nmbl.yml file. Try running nmbl create'
    );
  }
};
