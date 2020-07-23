import {
  isProjectNameValid,
  isProjectPathValid,
} from '../helpers/project-helpers';
import { doHook } from '../helpers/hook-helpers';
import { Command, flags } from '@oclif/command';

const debug = require('debug')('nmbl:do_hook');

export default class DoHook extends Command {
  static description =
    'Manually trigger a hook. This is really only useful for testing, because you need to pass JSON arguments.';

  static examples = [
    '$ nmbl do-hook create',
    '$ nmbl do-hook create "{ name: "my-project" }"',
  ];

  static flags = {
    path: flags.string({
      description: 'Path to the project to run hooks against.',
    }),
  };

  static args = [{ name: 'hookName', required: true }, { name: 'args' }];

  async run() {
    const { args, flags } = this.parse(DoHook);

    const hookName = args.hookName;

    if (!isProjectNameValid(hookName)) {
      this.error(
        'Please enter a valid project name. This is required for the hooks interface.'
      );
    }

    const hookArgs = JSON.parse(args.args);

    if (!hookArgs) {
      this.error('Failed to parse json args');
    }

    const path = flags.path ?? '.';

    if (!isProjectPathValid(path)) {
      this.error('Please enter a valid project path.');
    }

    this.log(`Running hook: ${hookName}`);

    debug('Running hook: %o', {
      hookName,
      hookArgs,
      path,
    });

    await doHook(path, args.hookName, args.args);
  }
}
