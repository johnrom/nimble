import { CreateHookArgs, BaseHookArgs } from '../types/hooks';
import {
  isProjectNameValid,
  isProjectPathValid,
} from './../helpers/project-helpers';
import { doHook, getBaseHookArgs } from './../helpers/hook-helpers';
import { isValidTemplate, fetchTemplate } from './../helpers/template-helpers';
import { Command, flags } from '@oclif/command';
import { mkdirp } from 'fs-extra';
import { prompt } from 'inquirer';
import { exec } from '../helpers/shell-helpers';
import { resolve } from 'path';

const debug = require('debug')('nmbl:create');

export default class Create<
  TBaseHookArgs extends BaseHookArgs
> extends Command {
  static description = 'Create a new Nmbl Project.';

  static examples = [
    '$ nmbl create ./my-project',
    '$ nmbl create --template johnrom/nimble-wp-template',
    '$ nmbl create ./my-project --template johnrom/nimble-wp-template',
  ];

  static flags = {
    template: flags.string({
      description:
        'Template in the form of a Git repo, like `johnrom/nimble-wp-template`.',
    }),
    path: flags.string({
      description: 'Path to the new project.',
    }),
    branch: flags.string({
      description: 'Branch of the Git repository used for the template.',
    }),
  };

  static args = [{ name: 'name', required: true }];

  async run() {
    const { args, flags } = this.parse(Create);

    const name = args.name;

    if (!isProjectNameValid(name)) {
      this.error('Please enter a valid project name.');
    }

    const path = flags.path ?? '.';

    if (!isProjectPathValid(path)) {
      this.error('Please enter a valid project path.');
    }

    let template = flags.template ?? '';
    let prompted = false;

    this.log(`Creating new Nmbl project "${name}" at: ${resolve(path)}`);

    debug('Validating arguments: %o', { template, path });

    while (!isValidTemplate(template)) {
      if (prompted) {
        this.warn('You must enter a valid Github repo as a template!');
      }

      // try and get a template name until the user gives up
      // eslint-disable-next-line no-await-in-loop
      const response = await prompt({
        name: 'template',
        type: 'input',
        message:
          'Enter a repo name to use as a template, like `johnrom/nimble-wp-template`',
      });

      template = response.template;
      prompted = true;
    }

    this.log(`Fetching template: ${template}`);
    debug('Fetching template: %o', { template, path });

    await mkdirp(path);
    await exec(`git init ${path}`);
    await fetchTemplate(template, path);

    let baseHookArgs = getBaseHookArgs(name, path);

    // this doesn't really use TBaseHookArgs...
    baseHookArgs =
      (await doHook<BaseHookArgs, TBaseHookArgs>(
        path,
        'get-args',
        baseHookArgs
      )) ?? baseHookArgs;

    await doHook(path, 'before-create', baseHookArgs);
    await doHook<CreateHookArgs>(path, 'create', baseHookArgs);
  }
}

/**
    cd $project_root

    # adding project name in case they differ
    do_hook "$project" "create" "$project_name"

    # update dev config
    #
    echo "Adding .yml file"
    local dev_template=$(<$template_dir/template.yml)

    dev_template=${dev_template//PROJECT/$project}
    dev_template=${dev_template//TLD/$tld}

    echo "$dev_template" > "$site_dir/$project.yml"

    # adding project name in case they differ
    do_hook "$project" "after-create" "$project_name"

    # starting docker-compose in detached mode
    up

    init $project

    if has_hook "$project" install; then

        if confirm "Do you want to run the initial setup?" Y; then
            install "$project"
        fi
    fi
 */
