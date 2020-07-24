import { getAbsoluteTemplatePath } from './template-helpers';
import { CLIError } from '@oclif/errors';
import { mkdirp } from 'fs-extra';
import { exec } from './shell-helpers';
import { which } from 'shelljs';
import * as path from 'path';
import getDebug from 'debug';

const debug = getDebug('nmbl:helpers:git');

export const throwIfGitNotExists = () => {
  if (!which('git')) {
    throw new CLIError('Please install Git before using.');
  }
};

export const fetchRepo = async (repo: string, path: string) => {
  throwIfGitNotExists();

  debug('fetching repo: %o', { repo, path });

  if (!repo) {
    throw new CLIError("Please enter a repo name like 'owner/repo'");
  }

  if (!path) {
    throw new CLIError('Please enter a directory');
  }

  await mkdirp(path);

  const repoUrl = `https://github.com/${repo}.git`;

  debug('cloning from repo url: %s', repoUrl);

  await exec(`git clone "${repoUrl}" "${path}"`);
};

export const linkSubmodule = async (
  repo: string,
  rootDirectory: string,
  relativePath: string
) => {
  throwIfGitNotExists();

  const projectRoot = path.resolve(rootDirectory);
  const submodulePath = path.resolve(projectRoot, relativePath);
  const submoduleParent = path.basename(submodulePath);

  const repoUrl = repo.startsWith('.')
    ? repo
    : `https://github.com/${repo}.git`;

  debug('linking submodule: %O', {
    repoUrl,
    submodulePath,
    repo,
    rootDirectory,
    relativePath,
  });

  // make every directory except the final directory
  await mkdirp(submoduleParent);

  await exec(
    `cd ${projectRoot} && git submodule add "${repoUrl}" "${relativePath}"`
  );
};
