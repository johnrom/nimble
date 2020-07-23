import { util } from 'chai';
import { promisify } from 'util';
import * as childProcess from 'child_process';

export const exec = promisify(childProcess.exec);

export const spawn = promisify(childProcess.spawn);
