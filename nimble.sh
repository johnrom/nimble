#!/bin/bash

# A Nimble Docker Environment
# Copyright (C) 2017 John Romberger web@johnrom.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Is the command ./_nimble/nimble.sh or nimble
if [[ $0 == \.* ]]; then
    command=$0
else
    command=`basename "$0"`
fi

script="$0"
source="$PWD/_nimble/nimble.sh"
tld="$(<_conf/tld.conf)"

if [[ -z "$tld" ]]; then
    tld="local"
fi

# Check that we're running in docker root directory
if [[ ! -f $source ]]; then
    echo "This command must be run from the docker root directory. Please navigate there to use Nimble."
    exit 1
fi

is_root(){

    # if script is found, we're ok. if not... ut oh
    if [[ -f $source ]]; then
        return 0
    fi

    return 1
}


is_mac(){

    # mac forwards loopback instead of using nat
    if [ "$(uname)" == "Darwin" ]; then
        return 0
    fi

    return 1
}


is_cygwin(){

    # check for mingw windows for handling of directories
    if [[ "$(uname -s)" = MINGW* ]]; then
        return 0
    fi

    return 1
}

# If file is not source, check that file is the same as source
# If not, call source, and replace this file
if ! [[ $command = "./_nimble/nimble.sh" ]]; then
    if ! cmp -s "$script" "$source"; then
        $source $@
        $source localize

        # Exit with source exit code
        exit $?
    fi
fi

nimble_root="$PWD"
project_root="$nimble_root"
site_root="$project_root/sites"
template_root="$project_root/_templates"
images_root="$project_root/images"
certs_root=$project_root/_conf/certs
argies="$@"
template=""

# directories in the VM may be different than in your command line
# i should make this nicer
nimble_root_command_line="$nimble_root"
nimble_root_vm="$nimble_root"
images_root_command_line="$images_root"
images_root_vm="$images_root"
site_root_command_line="$site_root"
site_root_vm="$site_root"

help(){
    echo "Setup:"
    echo "Usage: $command setup"
    echo "Sets up your environment"
    echo "Create new project:"
    echo "Usage: $command create \$project"
    echo "Init project:"
    echo "Usage: $command init \$project"
    echo "Install WP DB:"
    echo "Usage: $command install \$project"
    echo "Add Site to Hosts:"
    echo "Usage: $command hosts \$project"
    echo "Remove Site from Hosts:"
    echo "Usage: $command rmhosts \$project"
    echo "Delete all docker containers"
    echo "Usage: $command clear"
    echo "Delete all docker containers AND IMAGES!"
    echo "Usage: $command clear all"
    echo "Clean old docker volumes"
    echo "Usage: $command clean volumes"
    echo "Delete a project"
    echo "Usage: $command delete \$project"
    echo "Delete all projects"
    echo "Usage: $command delete all"
}

if is_cygwin; then
    nimble_root_command_line=${nimble_root_command_line//"/mnt/f/"/"f:/"}
    nimble_root_command_line=${nimble_root_command_line//"/mnt/c/"/"c:/"}
    nimble_root_command_line=${nimble_root_command_line//"/f/"/"f:/"}
    nimble_root_command_line=${nimble_root_command_line//"/c/"/"c:/"}
    images_root_command_line=${images_root_command_line//"/mnt/f/"/"f:/"}
    images_root_command_line=${images_root_command_line//"/mnt/c/"/"c:/"}
    images_root_command_line=${images_root_command_line//"/f/"/"f:/"}
    images_root_command_line=${images_root_command_line//"/c/"/"c:/"}
    site_root_command_line=${site_root_command_line//"/mnt/f/"/"f:/"}
    site_root_command_line=${site_root_command_line//"/mnt/c/"/"c:/"}
    site_root_command_line=${site_root_command_line//"/f/"/"f:/"}
    site_root_command_line=${site_root_command_line//"/c/"/"c:/"}
else

    if ! is_mac; then
        # bash on ubuntu for windows .. hopefully not a dual boot
        nimble_root_vm=${nimble_root_vm//"/mnt/f/"/"/f/"}
        nimble_root_vm=${nimble_root_vm//"/mnt/c/"/"/c/"}
        images_root_vm=${images_root_vm//"/mnt/f/"/"/f/"}
        images_root_vm=${images_root_vm//"/mnt/c/"/"/c/"}
        site_root_vm=${site_root_vm//"/mnt/f/"/"/f/"}
        site_root_vm=${site_root_vm//"/mnt/c/"/"/c/"}
    fi
fi


# nice yes/no function
confirm() {
    local prompt
    local default
    local REPLY

    # http://djm.me/ask
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question - use /dev/tty in case stdin is redirected from somewhere else
        read -p "$1 [$prompt] " REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

# nice variable confirmation function based off of the above
# first argument is a return variable
ask() {
    local required=0
    local REPLY
    local prompt=$2

    while true; do

        if [ -z "$prompt" ]; then
            prompt="Warning: There is no text for this question. Sorry!!!"
        fi

        if [ -z "$3" ]; then
            default="" # no default
        elif [ "$3" == "--required" ]; then
            required=1
            default=""
        else
            default="$3"
        fi

        if [ "$4" == "--required" ]; then
            required=1
        fi

        # Ask the question - use /dev/tty in case stdin is redirected from somewhere else
        read -p "$prompt [$default]: " REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        if [ ! -z "$REPLY" ] || [ $required -eq 0 ]; then
            eval "$1='$REPLY'"

            return 1
        fi
    done
}

args(){
    #!/bin/bash
    # Use -gt 1 to consume two arguments per pass in the loop (e.g. each
    # argument has a corresponding value to go with it).
    # Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
    # some arguments don't have a corresponding value to go with it such
    # as in the --default example).
    # note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )
    local i=1

    while [[ i -le "$#" ]]
    do
        local key="${!i}"
        local value_index=$(($i+1))
        local value="${!value_index}"

        case $key in
            -t|--template)
                template="$value"

                set -- "${@:1:i-1}" "${@:i+2}"
            ;;
            *)
                # unknown option
            ;;
        esac

        i=$(($i+1))
    done

    argies="$@"
}

# this is the magic right here
wp(){
    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to wp into! e.g., nimble wp myproject"
        return
    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with \`delete all\`. Try a new name!"
        return
    fi

    local project=$1
    local inner_dir="/var/www/html"

    bashitup "$project" "cd $inner_dir && wp ${*:2}"
}

localize(){
    mkdir ~/bin >& /dev/null
    rm ~/bin/nimble >& /dev/null

    ln -s "$source" ~/bin/nimble

    chmod +x ~/bin/nimble

    return $?
}

fetch_repo(){

    if [[ -z "$1" ]]; then
        echo "Please enter a repo name like 'owner/repo'"
        exit 1
    fi

    if [[ -z "$2" ]]; then
        echo "Please enter a directory"
        exit 1
    fi

    mkdir -p "$2"

    git clone "git@github.com:$1.git" "$2"
}

get_template(){

    if [[ -z "$1" ]]; then
        echo "Please select a template"
        exit 1
    fi

    local template_dir="$template_root/$1"

    if [ ! -d "$template_dir" ]; then
        echo "Template $1 does not exist, fetching..."

        fetch_repo "$1" "$template_dir"
    fi

    if [ ! -f "$template_dir/template.yml" ]; then
        echo "Invalid Template! Please check the git repo name"
    fi
}

has_hook(){
    local project="$1"
    local hook="$2"

    if [[ -z "$project" ]]; then
        echo "has_hook requires a project!"
        return 1
    fi

    if [[ -z "$hook" ]]; then
        echo "has_hook requires a hook (obvs)!"
        return 1
    fi

    if [ -f "$site_root/$project/hooks/$hook.sh" ]; then
        return 0

    else

        if [[ -z "$template" ]]; then

            if [[ -f "$site_root/$project/template.conf" ]]; then
                local project_template="$(<$site_root/$project/template.conf)"
            fi
        else
            local project_template="$template"
        fi

        if [[ ! -z "$project_template" ]]; then

            if [[ -f "$template_root/$project_template/hooks/$hook.sh" ]]; then
                return 0
            fi
        fi
    fi

    return 1
}

do_hook(){
    local project="$1"
    local hook="$2"

    if [[ -z "$project" ]]; then
        echo "do_hook requires a project!"
        return 1
    fi

    if [[ -z "$hook" ]]; then
        echo "do_hook requires a hook (obvs)!"
        return 1
    fi

    if [ -f "$site_root/$project/hooks/$hook.sh" ]; then
        source "$site_root/$project/hooks/$hook.sh"
    else
        # need a verbose feature
        # echo "Could not find a local hook. Using Template hook"

        if [[ -z "$template" ]]; then
            if [[ -f "$site_root/$project/template.conf" ]]; then
                local project_template="$(<$site_root/$project/template.conf)"
            fi
        else
            local project_template="$template"
        fi

        if [[ ! -z "$project_template" ]]; then

            if [[ -f "$template_root/$project_template/hooks/$hook.sh" ]]; then
                source "$template_root/$project_template/hooks/$hook.sh"
            else
                # Need a verbose option
                : # echo "Could not find project template hook"
            fi
        else
            # Need a verbose option
            : # echo "No template found"
        fi
    fi
}

create_front(){
    #
    # ugh I should redo this
    #
    local oldtemplate=template
    template="johnrom/nimble-nginx-proxy"

    local project="_front"
    local project_name="${project//_/}"
    local site_dir="$site_root/$project"
    local template_dir="$template_root/$template"

    # adding project name in case they differ
    do_hook "$project" "before-create" "$project_name"

    get_template "$template"

    # create directories
    #
    if [ -d "$site_dir" ]; then
        echo "Error: Folder already exists for project: $project. Exiting!"
        exit 1
    fi

    echo "creating project directory: $project"

    mkdir -p $site_dir

    echo "$template" > "$site_dir/template.conf"

    # update dev config
    #
    echo "Adding .yml file"
    local dev_template=$(<$template_dir/template.yml)

    echo "$dev_template" > "$site_dir/$project_name.yml"

    if [[ -d "$template_dir/conf" ]]; then
        cp -R "$template_dir/conf" "$site_dir/conf"
    fi

    if [[ -d "$template_dir/hooks" ]]; then
        cp -R "$template_dir/hooks" "$site_dir/hooks"
    fi

    # adding project name in case they differ
    do_hook "$project" "after-create" "$project_name"

    template="$oldtemplate"
}

create(){

    # requires project name
    if [[ -z "$1" ]]; then
        help
        return
    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with \`delete all\`. Try a new name!"
        return
    fi

    local project="$1"
    local site_dir="$site_root/$project"
    local www_dir="$site_root/$project/www"

    # adding project name in case they differ
    do_hook "$project" "before-create" "$project_name"

    default_template="$(<_conf/default-template.conf)"

    while [[ -z "$template" ]]; do
        default_template=${default_template-"johnrom/nimble-wp-template"}

        ask template "Please choose a template:" "$default_template" --required
    done

    local template_dir="$template_root/$template"

    get_template "$template"

    if [ ! -f "$template_dir/template.yml" ]; then
        echo "Invalid Template! Please check the git repo name"
        exit 1
    fi

    # create directories
    #
    if [ -d "$site_dir" ]; then
        echo "Error: Folder already exists for project: $project. Exiting!"
        exit 1
    fi

    echo "creating project directory: $project"

    mkdir -p $www_dir

    echo "$template" > "$site_dir/template.conf"

    cd $project_root

    # adding project name in case they differ
    do_hook "$project" "create" "$project_name"

    # update dev config
    #
    echo "Adding .yml file"
    local dev_template=$(<$template_dir/template.yml)

    dev_template=${dev_template//PROJECT/$project}
    dev_template=${dev_template//TLD/$tld}

    echo "$dev_template" > "$site_dir/$project.yml"

    if confirm "Do you want this project kept in git?" Y; then
        git add -f "$site_dir/template.conf"
        git add -f "$site_dir/$project.yml"
    else
        echo "$certs_root/$project.$tld.crt" >> .gitignore
        echo "$certs_root/$project.$tld.key" >> .gitignore
    fi

    # adding project name in case they differ
    do_hook "$project" "after-create" "$project_name"

    # starting docker-compose in detached mode
    up

    init $project

    if has_hook "$project" install; then

        if confirm "Do you want to run the initial setup?" Y; then
            install "$project"
        fi
    fi
}

setup(){
    localize

    if [ ! -f "$site_root/_front/front.yml" ]; then
        create_front
    fi
}

up(){
    echo "emptying docker-compose.yml"
    > docker-compose.yml

    echo "emptying docker-common.yml"
    > docker-common.yml

    local project
    local valid=0

    if [[ -z "$1" ]]; then
        eval "$(env)"
    else
        eval "$(env $1)"
    fi

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

down(){
    echo "stopping docker-compose"
    docker-compose down >& /dev/null

    echo "emptying docker-compose.yml"
    > docker-compose.yml

    echo "removing old cachegrind files"
    local directory

    for directory in $(ls "$site_root"); do

        if [ -d $site_root/"$directory" ]; then
            rm $site_root/"$directory"/cachegrind/* >& /dev/null
        fi
    done

    return 0
}

update(){
    echo "making sure containers are up"
    up >& /dev/null

    echo "stopping containers without emptying docker-compose"
    docker-compose down >& /dev/null

    echo "rebuilding local images"
    docker-compose build

    echo "updating containers"
    docker-compose pull

    up
}

restart(){
    down
    up
}

install(){
    do_hook "$1" install
}

run(){
    do_hook "$1" run "$@"
}

migrate() {
    local project=$1
    local inner_dir="/var/www/html"
    local url="$project.$tld"
    local remote

    if [[ -z $project ]];
    then
        echo "Usage: nimble migrate \$project"
        exit 1
    fi

    while true; do

        # Ask the question - use /dev/tty in case stdin is redirected from somewhere else
        read -p "Remote Domain [empty to continue, use www THEN non-www versions]: " remote </dev/tty

        # Default?
        if [[ -z "$remote" ]]; then
            return 0
        fi

        echo $remote
        echo $url
        echo "docker exec -i $project /bin/bash -c wp search-replace $remote $url"

        docker exec -i "$project" /bin/bash -c "wp search-replace $remote $url"
    done
}

cert() {

    if [[ -z "$1" ]]; then
        help
        return
    fi

    local project=$1

    openssl req \
        -newkey rsa:2048 -nodes \
        -subj "//C=US\ST=Pennsylvania\L=Philadelphia\O=MYORGANIZATION\CN=$project.$tld" \
        -keyout $PWD/_conf/certs/"$project.$tld.key" \
        -x509 -days 365 -out $PWD/_conf/certs/"$project.$tld.crt"
}

npm_install() {


    if confirm "Do you want to install NPM? It could take a while..." N; then
        # Install NPM Dependencies
        #
        echo "Installing NPM Dependencies"
        npm install
    fi
}

init() {

    if [[ -z "$1" ]]; then
        help
        return 1

    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with other things. Try a new name!"
        return 1
    fi

    local project="$1"
    local root="$nimble_root"
    local dir="$site_root/$project/www"
    local inner_dir="/var/www/html"

    if confirm "Do you want to add this project to your hosts?" Y; then
        hosts $project
    fi

    echo "Doing Init for $project"

    do_hook "$project" "init"

    if confirm "Do you want to generate certificates for this site?" Y; then
        cert $project
    fi

    echo "Restarting containers"
    restart
}

clone() {

    if [[ -z "$1" ]]; then
        help
        return
    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with other things. Try a new name!"
        return
    fi

    local project="$1"
    local dir="$site_root/$project/www"

    cd $dir

    if [[ -z "$2" ]]; then

        # Pull a repo
        ask repo "Repo URL (git@github.com:user/$project.git)" "" --required
    else
        local repo="$2"
    fi

    # initialize
    git init

    # set remote
    git remote add -t \* -f origin "$repo"

    # checkout master
    git checkout -f master

    cd $nimble_root
}

env() {
    local profile

    if [ -z "$1" ]; then
        profile="profiler_enable=0"
    elif [ "$1" == "profile" ]; then
        profile="profiler_enable=1"
    elif [ "$1" == "trigger" ]; then
        profile="profiler_enable_trigger=1"
    fi

    # run me before docker-compose up -d in order to set your env variable
    # for PHP to hook up to local xdebug listeners using remote_host
    # with docker beta we are just using the default docker network
    local ip="10.0.75.1"

    echo "export XDEBUG_CONFIG=\"remote_host=$ip remote_autostart=1 $profile\""
    echo "# to use this function to set up xdebug, use \`eval \$($command env \$machine_name)\`"
    echo "# \$machine_name is usually \`default\`, and is an optional parameter"
}

hosts() {
    # requires project name
    if [[ -z "$1" ]]; then
        help
        return
    fi

    local project=$1
    # check Git Bash hosts location
    local file="/c/Windows/System32/drivers/etc/hosts"

    if [ ! -f $file ]; then
        # check Ubuntu for Windows Bash hosts location
        local file="/mnt/c/Windows/System32/drivers/etc/hosts"

        if [ ! -f $file ]; then
            # check Mac hosts location
            local file="/private/etc/hosts"

            if [ ! -f $file ]; then
                echo "Cannot find hosts file"
                return
            fi
        fi
    fi

    local ip="10.0.75.2"

    # mac forwards loopback instead of using nat
    if [ "$(uname)" == "Darwin" ]; then
        local ip="127.0.0.1"

        if [ $EUID != 0 ]; then
            sudo "$0" hosts "$@"
            return $?
        fi
    fi

    rmhosts $project

    # Editing Hosts
    #
    echo "Adding $project.$tld to hosts file at $ip"
    echo "Adding phpmyadmin.$project.$tld to hosts file at $ip"
    echo "Adding webgrind.$project.$tld to hosts file at $ip"

    x=$(tail -c 1 "$file")

    if [ "$x" != "" ]
    then
        echo "" >> $file
    fi

    echo "$ip $project.$tld" >> "$file"
    echo "$ip phpmyadmin.$project.$tld" >> "$file"
    echo "$ip webgrind.$project.$tld" >> "$file"
}

rmhosts() {

    # requires project name
    if [[ -z "$1" ]]; then
        help
        return
    fi

    local file="/c/Windows/System32/drivers/etc/hosts"

    if [ ! -f $file ]; then
        local file="/mnt/c/Windows/System32/drivers/etc/hosts"

        if [ ! -f $file ]; then
            local file="/private/etc/hosts"

            if [ ! -f $file ]; then
                echo "Cannot find hosts file"
                return
            fi
        fi
    fi

    local project=$1
    local tab="$(printf '\t') "

    echo "Removing $project from $file"
    grep -vE "\s((phpmyadmin|webgrind)\.)?$project\.$tld" "$file" > hosts.tmp && cat hosts.tmp > "$file"

    rm hosts.tmp
}

clear() {
    echo "Removing docker containers"
    docker rm -f $(docker ps -a -q)

    if [ "$1" == "all" ]; then
        echo "Removing docker images"
        docker rmi -f $(docker images -q)
    fi
}

clean() {

    if [ "$1" == "volumes" ]; then
        echo "Cleaning old volumes"
        echo "Making sure docker is running so we register dangling volumes properly"
        docker-compose up -d

        if [ -z "$(docker volume ls -qf dangling=true)" ]; then
            echo "There are no orphaned docker volumes to clean"
        else
            echo "Verify the following volumes for deletion:"

            docker volume ls -qf dangling=true

            if confirm "Do all of these volumes look correct?! If any look like they are still necessary, don't proceed." N; then
                docker volume rm $(docker volume ls -qf dangling=true)
            fi
        fi
    fi
}

delete_one() {
    local project="$1"
    local dir="$site_root/$project/www"

    # Shut down docker-compose
    down

    # Remove from Git
    echo "Removing $project from Git"
    git rm --cached "$dir/.keep" >& /dev/null

    echo "Deleting *$project.yml from gitignore"
    grep -v "^.*$project\.yml.*$" .gitignore > .gitignore.tmp && mv .gitignore.tmp .gitignore

    rmhosts $project

    if confirm "Delete Project Files for $project? You could lose work! This is irreversible!" N; then
        echo "Deleting $project files"
        rm -rf "$site_root/$project" >& /dev/null
    fi

    if confirm "Delete Project Database for $project? This is also irreversible!" N; then
        echo "Deleting $project database"
        docker volume rm "$project"_db_volume >& /dev/null
    fi

    echo "Restarting Docker"
    restart
}

delete() {
    local root="$PWD"
    local project=$1

    if [[ $project == "all" ]]; then

        if confirm "Really remove all projects from Nimble? You will be asked if you want to delete files on a per-project basis." N; then
            for d in $(ls -d $site_root/*); do

                if [[ $(basename $d) == _* ]]; then
                    echo "Skipping $(basename $d)"
                    continue
                fi

                if [ -d $d ]; then
                    echo "Deleting $(basename $d)"
                    delete_one "$(basename $d)"
                fi
            done
        fi
    else
        delete_one $project
    fi
}

attach(){

    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to wp into! e.g., nimble wp myproject"
        return
    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with \`delete all\`. Try a new name!"
        return
    fi

    local project="$1"
    local command="docker"

    if hash winpty 2>/dev/null; then
        # make it a pseudo-tty
        local command="winpty docker"
    fi

    $command exec -it "$project" bash
}

bashitup(){
    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to wp into! e.g., nimble wp myproject"
        return
    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with \`delete all\`. Try a new name!"
        return
    fi

    local project="$1"
    local command="docker"

    if hash winpty 2>/dev/null; then
        # make it a pseudo-tty
        local command="winpty docker"
    fi

    $command exec -it "$project" bash -c "${*:2}"
}

# for containers that do not persist, aka use "run" instead of "exec"
bashrun() {
    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to wp into! e.g., nimble wp myproject"
        return
    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with \`delete all\`. Try a new name!"
        return
    fi

    # use docker-compose because if it's not persistent then docker doesn't know this container exists
    local project="$1"
    local command="docker-compose"

    if hash winpty 2>/dev/null; then
        local command="winpty $command"
    fi

    $command run "$project" "${*:2}"
}

# also the magic right here
bashraw() {
    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to wp into! e.g., nimble wp myproject"
        return
    elif [ "$1" == "all" ]; then
        echo "'all' is not a valid name for a project! Unfortunately, it conflicts with \`delete all\`. Try a new name!"
        return
    fi

    local project=$1

    docker exec -i "$project" bash -c "${*:2}"
}

test() {

    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to test! e.g., nimble test project plugin plugin-name"
        exit 1
    fi

    do_hook "$1" test "$@"

    local project=$1
}

install-tests() {

    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to scaffold tests for! e.g., nimble create-tests project plugin plugin-name"
        exit 1
    fi

    do_hook "$1" "install-tests" "$1" "$2" "$3"
}

create-tests() {

    # requires project name
    if [[ -z "$1" ]]; then
        echo "You need to provide the project to scaffold tests for! e.g., nimble create-tests project plugin plugin-name"
        exit 1
    fi

    do_hook "$1" "create-tests" "$1" "$2" "$3"
}

if [[ $1 =~ ^(help|up|down|create|migrate|init|delete|env|hosts|rmhosts|clear|localize|clean|install|cert|restart|update|wp|bash|bashraw|create-tests|install-tests|test|setup|run|attach)$ ]]; then

    if [[ $1 = "bash" ]]; then
        set -- "bashitup" "${@:2}"
    fi

    args "$@"

    $argies
else
  help
fi
