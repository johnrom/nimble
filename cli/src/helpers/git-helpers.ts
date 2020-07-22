import { mkdirp } from 'fs-extra';
import * as shell from 'shelljs';

export const throwIfGitNotExists = () => {
  if (!shell.which('git')) {
    throw 'Please install Git before using.';
  }
};

export const fetch_repo = (repo: string, relativePath: string) => {
  throwIfGitNotExists();

  if (!repo) {
    throw "Please enter a repo name like 'owner/repo'";
  }

  if (!relativePath) {
    throw 'Please enter a directory';
  }

  mkdirp(relativePath);

  const repoUrl = `https://github.com/${repo}.git`;
  const result = shell.exec(`git clone "${repoUrl}" "${relativePath}"`);

  if (result.code !== 0) {
    throw `Cloning from repository ${repoUrl} failed.`;
  }
};
