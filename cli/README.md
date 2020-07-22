nmbl-cli
========

A Nmbl Dev Workflow

[![oclif](https://img.shields.io/badge/cli-oclif-brightgreen.svg)](https://oclif.io)
[![Version](https://img.shields.io/npm/v/nmbl-cli.svg)](https://npmjs.org/package/nmbl-cli)
[![Downloads/week](https://img.shields.io/npm/dw/nmbl-cli.svg)](https://npmjs.org/package/nmbl-cli)
[![License](https://img.shields.io/npm/l/nmbl-cli.svg)](https://github.com/johnrom/nmbl-cli/blob/master/package.json)

<!-- toc -->
* [Usage](#usage)
* [Commands](#commands)
<!-- tocstop -->
# Usage
<!-- usage -->
```sh-session
$ npm install -g nmbl-cli
$ nmbl COMMAND
running command...
$ nmbl (-v|--version|version)
nmbl-cli/1.0.0-alpha1 win32-x64 node-v10.16.3
$ nmbl --help [COMMAND]
USAGE
  $ nmbl COMMAND
...
```
<!-- usagestop -->
# Commands
<!-- commands -->
* [`nmbl hello [FILE]`](#nmbl-hello-file)
* [`nmbl help [COMMAND]`](#nmbl-help-command)

## `nmbl hello [FILE]`

describe the command here

```
USAGE
  $ nmbl hello [FILE]

OPTIONS
  -f, --force
  -h, --help       show CLI help
  -n, --name=name  name to print

EXAMPLE
  $ nmbl hello
  hello world from ./src/hello.ts!
```

_See code: [src\commands\hello.ts](https://github.com/johnrom/nmbl-cli/blob/v1.0.0-alpha1/src\commands\hello.ts)_

## `nmbl help [COMMAND]`

display help for nmbl

```
USAGE
  $ nmbl help [COMMAND]

ARGUMENTS
  COMMAND  command to show help for

OPTIONS
  --all  see all commands in CLI
```

_See code: [@oclif/plugin-help](https://github.com/oclif/plugin-help/blob/v3.1.0/src\commands\help.ts)_
<!-- commandsstop -->
