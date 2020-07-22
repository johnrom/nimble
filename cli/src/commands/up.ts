import { Command, flags } from '@oclif/command';
import {
  maybeTruncate,
  tryStat,
  maybeCreate,
  tryRead,
} from '../helpers/file-helpers';
import { throwIfNotValidProject } from '../helpers/project-helpers';
import {
  readFile,
  createFile,
  readFileSync,
  readSync,
  writeFileSync,
} from 'fs-extra';
import { execSync } from 'child_process';

export default class Up extends Command {
  static description = 'Generate and run Docker-Compose';

  static examples = [`$ nmbl up`];

  static flags = {
    attach: flags.boolean({
      char: 'a',
      description: 'Attach to docker-compose',
    }),
  };

  async run() {
    throwIfNotValidProject();

    this.log('Processing docker-compose.yml');
    maybeCreate('docker-compose.yml');

    const templateFile = readFileSync('./nmbl.yml');
    const templateConfigs =
      tryRead('./_nmbl/template/template-configs.yml')?.toString() ?? '';

    const dockerCompose = templateFile
      .toString()
      .replace(/TEMPLATE_CONFIGS/, templateConfigs);

    writeFileSync('docker-compose.yml', dockerCompose);

    const { flags } = this.parse(Up);

    if (flags.attach) {
      execSync('docker-compose up');
    } else {
      execSync('docker-compose up -d');
    }
  }
}
/**
up() {
    for project in $(ls -d $site_root/*)
    do
        local project_raw_name="$(basename $project)"
        local project_name=${project_raw_name//"_"/""}

        echo "Processing project: $project_name"

        if [[ ! -f $project/$project_name.yml ]]; then
            echo "Warning: $project does not have a valid .yml file. Skipping!"
        else

            if [[ -f "$project/template.conf" ]]; then
                # I am tired
                local project_template="$(<$project/template.conf)"

                get_template "$project_template"
            fi

            # docker does not like relative directories
            local this_template=$(<$project/$project_name.yml)
            this_template=${this_template//SITEROOT/"$site_root_vm/$project_raw_name"}
            this_template=${this_template//NIMBLE/"$nimble_root_vm"}
            this_template=${this_template//NIMCMD/"$nimble_root_command_line"}
            this_template=${this_template//IMAGES/"$images_root_command_line"}
            this_template=${this_template//COMMON/"$nimble_root_command_line/docker-common.yml"}

            echo "$this_template" >> "docker-compose.yml"
            valid=1

            do_hook "$project_name" "before-up"
        fi
    done

    echo "Processing Common Template"

    for owner in $(ls -d $template_root/*)
    do
        local owner_name="$(basename $owner)"

        for template_directory in $(ls -d $template_root/$owner_name/*)
        do
            local repo_name="$(basename $template_directory)"

            echo "Processing template: $owner_name/$repo_name"

            if [[ ! -f "$template_directory/common.yml" ]]; then
                echo "Warning: $owner_name/$repo_name does not have a valid common file. Skipping!"
            else

                # quick hack because docker for windows does not like relative directories
                local this_template=$(<"$template_directory/common.yml")

                this_template=${this_template//NIMBLE/"$nimble_root"}
                this_template=${this_template//IMAGES/"$images_root_command_line"}

                if is_cygwin; then
                    this_template=${this_template//"/mnt/f/"/"/f/"}
                    this_template=${this_template//"/mnt/c/"/"/f/"}
                fi

                echo "$this_template" >> "$nimble_root/docker-common.yml"
            fi
        done
    done

    if [[ $valid = 1 ]]; then
        echo "Common templates assembled. Starting docker-compose in detached mode"

        if [ -z "$1" ] || ! [ "$1" = "attach" ]; then
            local command="docker-compose up -d"
        else
            local command="docker-compose up"
        fi

        $command
    else
        echo "Did not find any valid projects! Did you run setup?: nimble setup"
    fi
}

 */
