import { promisify } from 'util';
import * as fs from 'fs';

export const truncateFile = promisify(fs.truncate);

export const tryTruncateFile = async (
  path: fs.PathLike,
  len?: number | null
) => {
  try {
    await truncateFile(path, len);

    return true;
  } catch {}

  return false;
};

export const statFile = promisify(fs.stat);

export const tryStatFile = (path: fs.PathLike): Promise<fs.Stats | null> => {
  try {
    return statFile(path);
  } catch {}

  return Promise.resolve(null);
};

export const readFile = promisify(fs.readFile);

export const tryReadFile = (path: fs.PathLike): Promise<Buffer | null> => {
  try {
    return readFile(path);
  } catch {}

  return Promise.resolve(null);
};

export const openFile = promisify(fs.open);
export const closeFile = promisify(fs.close);
export const writeFile = promisify(fs.writeFile);

export const createFile = async (path: fs.PathLike) => {
  if (tryStatFile(path)) {
    throw new Error(`File ${path} already exists.`);
  }

  writeFile(path, '');
};

export const tryCreateFile = async (path: fs.PathLike) => {
  try {
    await createFile(path);

    return true;
  } catch {}

  return false;
};
