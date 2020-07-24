# Nimble

*A Cross-Platform Cross-Project MultiTenant Docker Environment*

Welcome to `nimble`, a project focused on making your Docker experience as smooth as possible. The core philosophy of `nimble` is *Straight to the Code*, meaning no messing with configuration settings and environment variables in order to do a *hello world* in your application. The purpose of `nimble` is one that drives many of us -- getting right to the good stuff, and not worrying about variables outside of the code. It is about allowing your projects, your teams, or your potential customers to get *right to the code* in their first experience with a project.

Think about a PHP developer trying to install node.js for the first time. There are a million different pieces that someone new to Node will not understand. NPM? NVM? N? WAHT? Of course, you'll need to learn about all of that stuff, because it is in itself powerful. But the first thing you want is to have the thing running without a 2 hour walkthrough for setting it up. I like to reverse-engineer, so at least this is how I think. And the first time it has been set up correctly should be perfectly replicable so that these steps don't have to be repeated! I never want to read that walkthrough again! This was my first time with Docker. Figuring out how to build a site's microservices was a pain. The very first time I built an entire `docker-compose.yml` was fraught with endless errors that were almost untraceable, because you have to figure out how everything works together before *anything works at all*.

So here's where `nimble` comes in. Let's say, for example, I found what I think to be [a pretty good WordPress dev environment](https://github.com/johnrom/nimble-wp). What if I could ask you to check out my dev environment with a single command? If you already had `nimble` as your dev environment, that wouldn't be a problem!

### So how would this work?

First install Docker for [Windows](https://docs.docker.com/docker-for-windows/install/) or [Mac](https://docs.docker.com/docker-for-mac/install) (maybe even Linux, but I make no promises), make sure you have bash and a bash version of Git, add `~/bin` to your PATH and then let's begin.

Let's get started with a [basic drop-in environment](https://github.com/johnrom/nimble-root). I've crafted this environment to be project-neutral, but you could potentially have dozens of projects sitting there, ready to be shared with your team, or a single site ready to be booted up so a user can try out your theme. Download that environment to a nice place on your C:, F: or wherever it lives on Mac.

In this environment, there isn't much but a few folders, a few git-related files, and a submodule of [Nimble](https://github.com/johnrom/nimble). If you open the `conf` folder, you'll see a `default-template.conf` and `tld.conf`. `tld.conf` just says "this is the TLD for my sites". I like `mysite.local`, but you can switch this to `mysite.dev` or whatever, at any time. However, the magic really happens in `default-template.conf`. `default-template.conf` is a file with one line saying what Git repo to use as a template to spin up new projects. By default, it is the previously mentioned [WordPress Environment](https://github.com/johnrom/nimble-wp), but it could be this basic [Ghost Nodejs Environment](https://github.com/johnrom/nimble-ghost). Let's leave these files as they are for now, though.

Our first step is to set up a reverse proxy so any sites you create can be accessed via your browser. Boot up a command line, BASH, Git Bash, Terminal, etc, with admin/sudo privileges within the directory you downloaded the drop-in environment, and run:

`./_nimble/nimble.sh setup`

If you added `~/bin` to your PATH, you can now just type `nimble`. What happened now is that a reverse proxy is sitting in a docker container listening for other web-accessible containers. Now how would you like to check out my dev environment with a single command?

`nimble create --template johnrom/nimble-wp test`

You can run through the defaults for now, and when it asks to install WordPress enter whatever information you'd like. Congratulations! You now have `twentyseventeen` running on WordPress at `test.local`! If you're here to find out what `nimble-wp` can do for you, [check out the readme for that project](https://github.com/johnrom/nimble-wp). But for now, what can `nimble` itself do for you?

You'll notice that by using the `nimble-wp` template, a folder was created at `_templates/johnrom/nimble-wp`. But what if you don't like the WordPress image I used? You can copy the folder, make some changes to the docker-compose configuration, and upload it as `github.com/youruser/your-environment` and the next time you pull, you can use `--template youruser/your-environment`. I won't be offended! Then, if you want someone else to try out *your environment*, you can just tell them to create a `nimble` project using your environment.

Whenever you'd like to start your Docker server, like on a reboot, just run `nimble up` (from the root directory), restart with `nimble restart` and shut it down with `nimble down`.

**Please be safe with your computer and only use templates that you trust**

This is only the beginning, so be sure to look out for a updates to this documentation once I polish up some of the other commands! For now, here is a list:

### Coming Soon

- Soon I will be introducing `hooks`, which will be a template's way of introducing custom functionality. Please make sure to use them responsibly!
- I will be thoroughly testing Mac, as I have made significant changes to this since the last time I used one.. Feel free to report any issues you find on Mac in the meantime!
- Testing framework: I will be attempting to expand the current phpunit test framework to other test frameworks on a per-template level, but it will be a challenge
- Finishing the subcommands below. I recently developed the entire project to leverage templates, so some functionality may be missing / broken / buggy.
- Reimagining configuration. The current configuration uses a file per configuration option.. which is just me being lazy. But not to worry! I'll be sure the files still work for future updates.

## Old Documentation (TODO)

### `nimble create mysite`

- creates folders
- downloads necessary templates
- (optional) clones repository
- (optional) installs NPM
- (optional) installs WordPress
- (optional) adds to your `hosts` file.
- starts the new containers.

### `nimble up`

This runs docker, except it will first create your custom-tailored docker-compose file and set up environment variables. **Use this instead of docker-compose up -d!**

Running `nimble up profile` with the default template will start PHP with `xdebug.profiler_enable=1` and `nimble up trigger` will allow you to add `XDEBUG_PROFILE` to the end of any URL to start profiling. These profiles are accessible at `webgrind.$project.local`

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

WP Cli is available for each WordPress project using `nimble` and the project name. This helps to not have to log in to the VM / container itself because the commands are rather obnoxious. If my project is called `press`, this would be an example command:

`nimble wp press plugin install hello-dolly`

Please note the current WP Cli implementation has some issues with Windows / Git Bash. I haven't been able to figure out implementing spaces in some arguments quite yet.

## Running bash commands (useful for testing)

Bash is available for each project using the subcommand `bash`. Please note that any changes to the container outside of WordPress / Database changes may not be preserved next time the site starts! For editing the way the site works fundamentally, you'll have to create a new docker image and edit the `$project.yml`. If my project is called `press`, this would be an example command:

`nimble bashitup press date`

Please note the current `bashitup` implementation has some issues with Windows / Git Bash. I haven't been able to figure out implementing spaces in commands quite yet. If you're inclined, it might be better to use it with [WSL Bash](https://msdn.microsoft.com/en-us/commandline/wsl/about).

## PHPUnit

Testing your Themes and plugins is possible with this framework using [my custom WP image](https://github.com/johnrom/docker-wordpress-wp-cli-xdebug). However, it is not in an ideal state, as it pollutes the plugin with test files and bootstrapping files. I want to reimplement it in a less intrusive fashion. However, if you're interested in working with WordPress and Unit Testing, this framework can help you get started without running into a ton of low-level configuration issues -- let's get *right to the code*! Run the following commands from the root directory, replacing `$project-name` with your project name, `$type` with "plugin" or "theme" (WP Core Tests coming soon), and `$plugin-or-theme-name` with the name of your plugin or theme. This has currently only been tested with plugins as I have not unit tested any themes!

- `nimble create-tests $project-name $type $plugin-or-theme-name`
- `nimble test $project-name $type $plugin-or-theme-name`

The second command should give you an actual readout of a phpunit test, with the one default test provided in `test-sample.php`. Now you can edit it, create more files and organize your tests! Try changing `$this->assertTrue( true );` to `$this->assertTrue( false );` and see what happens.

*[More about PHPUnit](https://phpunit.de/manual/current/en/writing-tests-for-phpunit.html)*

## Roadmap

- PHPUnit Reimplementation
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
