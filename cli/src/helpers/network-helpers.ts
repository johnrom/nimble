import { exec } from './shell-helpers';
import { mkdirp } from 'fs-extra';
import { tryStatFile } from './file-helpers';

export const ensureNetwork = async () => {
  if (!tryStatFile('~/.nmbl/network/.git')) {
    await mkdirp('~/.nmbl/network');
    await exec(
      'cd ~/.nmbl/network && nmbl create --template=johnrom/nmbl-network-template'
    );
  }
};
