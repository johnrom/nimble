import {
  truncateSync,
  PathLike,
  Stats,
  statSync,
  openSync,
  closeSync,
  readFileSync,
} from 'fs';

export const maybeTruncate: typeof truncateSync = (path, len) => {
  try {
    truncateSync(path, len);
  } catch {}
};

export const tryStat = (path: PathLike): Stats | null => {
  try {
    return statSync(path);
  } catch {}

  return null;
};

export const tryRead = (path: PathLike) => {
  try {
    return readFileSync(path);
  } catch {}

  return null;
};

export const create = (path: PathLike) => {
  const handle = openSync(path, 'w');

  closeSync(handle);
};

export const maybeCreate = (path: PathLike) => {
  try {
    return create(path);
  } catch {}

  return null;
};
