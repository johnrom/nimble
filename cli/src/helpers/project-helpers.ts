import { CLIError } from '@oclif/errors';
import { tryStat } from './file-helpers';

export const throwIfNotValidProject = async () => {
  if (!tryStat('_nmbl')) {
    throw new CLIError(
      'Please run this command from the root of a nmbl project. It will contain a `_nmbl` folder.'
    );
  }

  if (!tryStat('nmbl.yml')) {
    throw new CLIError(
      'Project does not have a valid nmbl.yml file. Try running nmbl create'
    );
  }
};
