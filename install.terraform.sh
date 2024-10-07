#!/usr/bin/env bash

##  +-----------------------------------+-----------------------------------+
##  |                                                                       |
##  | Copyright (c) 2019-2021, Andres Gongora <mail@andresgongora.com>.     |
##  |                                                                       |
##  | This program is free software: you can redistribute it and/or modify  |
##  | it under the terms of the GNU General Public License as published by  |
##  | the Free Software Foundation, either version 3 of the License, or     |
##  | (at your option) any later version.                                   |
##  |                                                                       |
##  | This program is distributed in the hope that it will be useful,       |
##  | but WITHOUT ANY WARRANTY; without even the implied warranty of        |
##  | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         |
##  | GNU General Public License for more details.                          |
##  |                                                                       |
##  | You should have received a copy of the GNU General Public License     |
##  | along with this program. If not, see <http://www.gnu.org/licenses/>.  |
##  |                                                                       |
##  +-----------------------------------------------------------------------+

##
##  QUICK INSTALLER
##

##==============================================================================
##  DEPENDENCIES
##==============================================================================
[ "$(type -t include)" != 'function' ] && { include(){ { [ -z "$_IR" ] && _IR="$PWD" && cd $(dirname "${BASH_SOURCE[0]}") && include "$1" && cd "$_IR" && unset _IR; } || { local d=$PWD && cd "$(dirname "$PWD/$1")" && . "$(basename "$1")" && cd "$d"; } || { echo "Include failed $PWD->$1" && exit 1; }; };}

include 'bash-tools/bash-tools/user_io.sh'
include 'bash-tools/bash-tools/shell.sh'

##==============================================================================
##  FUNCTIONS
##==============================================================================

##------------------------------------------------------------------------------
##  INSTALL SCRIPT
installScript() {
    ## ARGUMENTS
    local operation=$1
    local script_name=$2

    ## EXTERNAL VARIABLES
    if [ -z $INSTALL_DIR ]; then echo "INSTALL_DIR not set"; exit 1; fi
    if [ -z $RC_FILE ]; then echo "RC_FILE not set"; exit 1; fi
    if [ -z $CONFIG_DIR ]; then echo "CONFIG_DIR not set"; exit 1; fi

    ## LOCAL VARIABLES
    local dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    local script="${INSTALL_DIR}/${script_name}.sh"
    local source_script="${dir}/synth-shell/${script_name}.sh"
    local config_template_dir="${dir}/config_templates"
    local edit_text_file_script="$dir/bash-tools/bash-tools/edit_text_file.sh"
    source "$edit_text_file_script"

    ## TEXT FRAGMENTS
    local hook=$(printf '%s'\
    "\n"\
    "##-----------------------------------------------------\n"\
    "## ${script_name}\n"\
    "if [ -f ${script} ] && [ -n \"\$( echo \$- | grep i )\" ]; then\n"\
    "\tsource ${script}\n"\
    "fi")

    ## INSTALL/UNINSTALL
    case "$operation" in
        uninstall)
            ## REMOVE HOOK AND SCRIPT
            printInfo "Removed $script_name hook from $RC_FILE"
            editTextFile "$RC_FILE" delete "$hook"
            if [ -f $script ]; then rm $script; fi
            ;;

        install)
            ## CHECK THAT INSTALL DIR EXISTS
            if [ ! -d $INSTALL_DIR ]; then
                printInfo "Creating directory $INSTALL_DIR"
                mkdir -p $INSTALL_DIR
            fi

            ## CREATE EMPTY SCRIPT FILE
            printInfo "Creating file $script"
            if [ -f $script ]; then
                rm $script
            fi
            touch "$script" || exit 1
            chmod 755 "$script"

            ## ADD HOOK TO /etc/bash.bashrc
            printInfo "Adding $script_name hook to $RC_FILE"
            editTextFile "$RC_FILE" append "$hook"
            ;;

        *)
            echo $"Usage: $0 {install|uninstall}"
            exit 1
            ;;
    esac
}

##------------------------------------------------------------------------------
installAll() {
    for script in $SCRIPTS; do
        installScript install "$script"
    done
}

##------------------------------------------------------------------------------
uninstallAll() {
    for script in $SCRIPTS; do
        installScript uninstall "$script"
    done
}

##==============================================================================
##  MAIN
##==============================================================================
installerSystem() {
    local option=$1
    local INSTALL_DIR="/usr/local/bin"
    local CONFIG_DIR="/etc/synth-shell"
    local RC_FILE="/etc/bash.bashrc"

    if [ $(id -u) -ne 0 ]; then
        printError "Please run as root"
        exit
    fi

    printInfo "Running systemwide"

    case "$option" in
        uninstall) printInfo "Uninstalling synth-shell"
                   uninstallAll
                   printSuccess "synth-shell was uninstalled"
                   ;;
        ""|install) printInfo "Installing synth-shell"
                    installAll
                    printSuccess "synth-shell was installed"
                    ;;
        *) echo "Usage: $0 {install|uninstall}" & exit 1
    esac
}

installerUser() {
    local option=$1
    local INSTALL_DIR="${HOME}/.config/synth-shell"
    local CONFIG_DIR="${HOME}/.config/synth-shell"
    local user_shell=$(getShellName)

    printInfo "Running for user $USER"

    case "$user_shell" in
        bash) local RC_FILE="${HOME}/.bashrc" ;;
        zsh) local RC_FILE="${HOME}/.zshrc" ;;
        *) local RC_FILE="${HOME}/.bashrc"
           printInfo "Could not determine user shell. I will install the scripts into $RC_FILE"
    esac

    case "$option" in
        uninstall) printInfo "Uninstalling synth-shell"
                   uninstallAll
                   printSuccess "synth-shell was uninstalled"
                   ;;
        ""|install) printInfo "Installing synth-shell"
                    installAll
                    printSuccess "synth-shell was installed"
                    ;;
        *) echo "Usage: $0 {install|uninstall}" & exit 1
    esac
}

installer() {
    local SCRIPTS="
        synth-shell-greeter
        synth-shell-prompt
        better-ls
        alias
        better-history
    "

    installerUser install
}

installer "$@"
