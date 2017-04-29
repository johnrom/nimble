# A Nimble Docker Environment

*"I am not afraid of storms for I am learning how to sail my ship."*

Welcome to `nimble`, a Docker shell project hoping to make your experience with Docker as smooth as possible. This project is particularly biased towards the use of WordPress, but it is certainly applicable to other platforms. There are a few dependencies to get the full experience out of this plugin.

* Install Docker
* Install Git on the Command Line
* Add `~/bin` to your PATH
* Run your Shell as Administrator on Windows (for automatic updating of your hosts file)

Along with those dependencies, there are some assumptions this command makes:

* If on Windows, Docker for Windows only works on Windows 10 Professional. If you're on a different version of Windows, try Docker Toolbox, but mileage may vary
* This assumes you use the default ports, IPs, and basic out-of-the-box functionality of Docker. 10.0.75.0 is the IP address it likes to route, 0.0.0.0:2075 is the port it likes to call docker on. I didn't want to mess with any of this.
* This assumes, if you're on Windows, that you use the `C` drive for your hosts file. Sorry!
* It probably assumes a bunch of other things.

*This is untested, wild technology. Use this command at your own risk. Even I'm afraid some days. Are you afraid? If not, then you can maybe read through the script and understand what it's doing. Then you can probably even tell me how to make it better. And submit some pull requests and junk. Who knows! Either way, you're ready to move to the installation process.*

## So what does it do?

This script allows you to maintain a variety of projects that will live at `http://*.local/` -- if you choose to generate certs for a project, you will also be able to access it on `https://*.local`, but it will of course be untrusted.

If my project's name is `press`, you can use the following urls:

- `http://press.local`
- `http://phpmyadmin.press.local`
- `http://webgrind.press.local` (if run using `nimble up profile`)

Biased towards WP, this script will ask if you'd like to install WP, and if so it will ask you questions during project creation about the site. It uses [wp-cli](https://github.com/wp-cli/wp-cli) to achieve this.

It will also offer to clone a Git repo (connected to your Git used in this terminal, so if you can pull it from the terminal, you can pull it with `nimble`). If you choose to clone a Git repo, it'll also offer to run `npm install` -- because I'm lazy.

Additionally, by default it will use my WordPress image with WP-CLI and XDebug which is based on Conetix's version. With this, you can listen to WordPress using any Xdebug plugins on port `9000` for your editor of choice.

- https://hub.docker.com/r/johnrom/docker-wordpress-wp-cli-xdebug/
- https://github.com/johnrom/docker-wordpress-wp-cli-xdebug

Even if you're not impressed by the fact that one command can boot virtually unlimited sites (I mean, we had Vagrant/VVV already, right?) this new system has a number of benefits.

The primary distinction is that MySQL, PHP, NGINX, Apache and associated software is isolated for each site. This means you can have different versions of each. Unreal! Just go to `_projects/yourproject.yml` and change the service/image to whatever version you would like -- the data, however, may be lost, so only do that at the start of a project.

Additionally, there is a common configuration file: `docker-common.yml`, whereby a change to this file can dramatically change the outcome of a `nimble up` for **all sites** using those templates! That means even though I already have 10 sites, I was able to set them all up with XDebug and PHPMyAdmin in minutes, not hours. Kind of cool.

Now that the benefits are out of the way, let's introduce the subcommands

## Step one: Pull this repository

I like this project to sit at `~/projects/docker`. That way it can live alongside my other projects, like `~/projects/dotnet` and `~/projects/shopify`.

I also like this project to be at My Documents on Windows, at `~\Documents\projects\docker`, though that is just because it's easier to get to than your user folder when navigating Windows.

It may be required that it lives in your user directory... or it may not. It used to be before Docker for Windows/Docker for Mac because only your user folder was shared with the VM. You can try putting it anywhere, but if it doesn't work, you should probably put it in your user folder.

## Step two-point-five: Create a shortcut

Whether you're in macOS or Windows, `~/bin` AKA your user binaries folder must be in your path in order to use the shortcut.

In the root folder of this repo, run the command `./nimble.sh localize`. This will create a shortcut command so you don't have to type `./nimble.sh`.

`./nimble.sh` => `nimble`

## Step three: Check your connection to docker

You must have Docker, Docker for Windows, or Docker for Mac installed for this to work. This should go without saying! I haven't had Docker Toolbox for months now, so I have no idea if this script will work with it. Maybe it does, though.

To check your connection to docker, open your Terminal, Git Bash, or Ubuntu for Windows, and enter `docker ps`. You should see a table, probably empty, showing that you have no (or some) containers running. This is good. If you see an error, you will have to verify that Docker is working before continuing on. Good luck!

## Step four: Create a new project!

Anchors aweigh! Let's provision some sites using the `create` command, explained below.

## Nimble Subcommands

### `nimble create mysite`

- creates folders
- creates docker-compose.yml configuration
- (optional) clones repository
- (optional) installs NPM
- (optional) installs WordPress
- (optional) adds `project.local`, `phpmyadmin.project.local` and `webgrind.project.local` to your `hosts` file. Webgrind will only work if you use `nimble up profile`
- starts the new containers.

What a boss!

### `nimble up`

This runs docker, except it will first create your custom-tailored docker-compose file and set up environment variables. **Use this instead of docker-compose up -d!**

Running `nimble up profile` will start PHP with `xdebug.profiler_enable=1` and `nimble up trigger` will allow you to add `XDEBUG_PROFILE` to the end of any URL to start profiling. These profiles are accessible at `webgrind.$project.local`

### `nimble down`

This stops docker. It just runs `docker-compose down`... but I figured why have that one command be the only time you use `docker-compose`?

### `nimble restart`

This is `nimble down` + `nimble up`.

### `nimble update`

This will update all of your images, like latest version of WordPress (supported by the Image you are using, if it's mine it's probably out of date already! :( ) and latest version of mariadb, webgrind, etc.

### `nimble install mysite`

This will run `wp core install` on your site, and ask you some questions. *Won't work if it's already installed!*

### `nimble init mysite`

Did you already download and install WordPress? Is the Docker-compose file already prepared with a specific site? `init` will ask you piece by piece if you want to pull a repo, add to hosts, install npm, etc., without the initial creation.

### `nimble env`

This is mostly internal, but you can eval it if you want to be weird.

### `nimble hosts mysite`

This, quite simply, will add `mysite.local` `phpmyadmin.mysite.local` and `webgrind.mysite.local` to your hosts file, deleting any other instances of these URLs. Make sure you run it as an administrator!

### `nimble rmhosts mysite`

This, quite obviously, will do the opposite of the above.

### `nimble clean volumes`

If the process for using `nimble delete $project` isn't followed or you chose not to delete a DB or two, you could find many extra volumes when you run a `docker volume ls`. Get rid of these by running `nimble clean volumes`

### `nimble clear [all]`

This one is will delete any remnants of docker containers. Adding `all` (or any text) afterwards will also delete all the images in docker. Useful for busting cache and the like.

### `nimble delete mysite|all`

Do you hate your new site? Are you having serious problems? Delete the whole thing. It'll ask if you want to remove the actual files, which I don't recommend unless you're definitely done with your data (ideally, it's in Git!)

Do you hate `nimble`? Do you wish that it would get rid of every project? A fresh start is nice from time to time. You don't have to move to another country to get this fresh, cathartic feeling -- just write `nimble delete all`!

*There will be a confirmation dialog to delete the files for each project.*

## XDebug

Xdebug is supported on port 9000 for those advanced users. See [this Git repo](https://github.com/johnrom/docker-wordpress-wp-cli-xdebug) for more details.

## PHPMyAdmin

Every site generated with `nimble create` will have a respective PHPMyAdmin install at `phpmyadmin.project.local`. There is no login required for this portal.

## WP Cli

WP Cli is available for each project using `nimble` and the project name. This helps to not have to log in to the VM / container itself because the commands are rather obnoxious. If my project is called `press`, this would be an example command:

`nimble wp press plugin install hello-dolly`

Please note the current WP Cli implementation has some issues with Windows / Git Bash. I haven't been able to figure out implementing spaces in commands quite yet.

## Running bash commands (useful for testing)

Bash is available for each project using the subcommand `bashitup`. Please note that any changes to the container outside of WordPress / Database changes may not be preserved next time the site starts! For editing the way the site works fundamentally, you'll have to create a new docker image and edit the `$project.yml`. If my project is called `press`, this would be an example command:

`nimble bashitup press date`

Please note the current `bashitup` implementation has some issues with Windows / Git Bash. I haven't been able to figure out implementing spaces in commands quite yet. If you're inclined, it might be better to use it with [WSL Bash](https://msdn.microsoft.com/en-us/commandline/wsl/about).

## Roadmap

- PHPUnit (I've implemented this before, I just have to reimplement it in the open source version)
- Web Templates for creating, for example, a custom NodeJS environment (`nimble create --template github.com/templatemaker/template.git`)
- Extensions for adding functionality to the script
- Maybe an upgrade to an actual programming language / GUI if this becomes popular

# Debugging

When this script works, it will change your life. But when Docker decides not to cooperate, your life will become a living nightmare. It's been less of a problem with later updates to the platform, but there is some troubleshooting involved with Docker. Most of the time it comes down to:

* Is your Drive Shared with the Docker VM?
* Run `nimble restart`
* If that doesn't work, restart your machine.
* If you're still having problems, feel free to PM me on WordPress Slack

In addition:

- Mac support is not guaranteed.
- Linux support was never tested once.
- Windows support is probable but also not guaranteed.

### Happy Sailing!

*Special thanks to [Nimblelight](http://nimblelight.com) for supporting this open source project.*
