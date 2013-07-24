#!/bin/bash

########################################
# Extra Line for readability.
########################################
echo 


########################################
# See if we are the root user.
########################################
USERNAME=$(whoami)
POWERUSER=$"root"

if [ $USERNAME != $POWERUSER ]; then
    echo "You must be root user to do an svncheckout."
    echo
    exit 1;
fi


########################################
# Program Cosntants
########################################
SVN_URI="http://svn.w2pc.com/repos/"
WWW_DIR="/var/app/www/html/"
BACKUP_DIR="/var/app/www/backups/"
DIRECTORY_NAME=$(date +"%Y%m%d%H%M%S")

########################################
# Server Cosntants
########################################
DEVNAME=$"dev.w2pc.com"
TESTNAME=$"test.w2pc.com"
PRODNAME=$"www.w2pc.com"

########################################
# See which server we are running on so we can check out only that tag.
########################################
curr_box=$( hostname )
if [ $curr_box == $DEVNAME ]; then
    server=$"dev"
elif [ $curr_box == $TESTNAME ]; then
    server=$"test"
elif [ $curr_box == $PRODNAME ]; then
    server=$"prod"
else
    echo "ERROR: This server isn't setup to run with this script, you will need to modify the script...."
    echo
    exit 1
fi

########################################
# IMPORTANT:: Make sure all paths exists.
########################################
if [[ ! -d $BACKUP_DIR ]]; then
    echo "NOTE:: The backup directory didn't exist, creating directory at: "$BACKUP_DIR
    mkdir -p $BACKUP_DIR
fi

if [[ ! -d $WWW_DIR ]]; then
    echo "NOTE:: The www directory didn't exist, creating directory at: "$WWW_DIR
    mkdir -p $WWW_DIR
fi

########################################
# Select repository and project.
########################################
function runsvn
{
    ########################################
    # Check to see if the project is really located at the URI given.
    ########################################
    if [[ ! $(svn log -q $SVN_URI$reponame"/tags/$projectname/"$server"_"$version) ]]; then
        echo "ERROR:: check your paramenters, '$SVN_URI$reponame"/tags/"$server"_"$projectname"-"$version' doesn't exist."
        echo
        exit 1
    fi

    ########################################
    # Check to see if we already have a soft link.
    ########################################
    if [ -h $WWW_DIR$projectname ]; then
        echo "Softlink exists.  Create backups"
        old_link_dir=$( readlink "$WWW_DIR$projectname")

        ########################################
        # Need to copy current existing real directory to backup
        ########################################
        echo "Copying existing real directory to '$BACKUP_DIR'"
        cp -R $old_link_dir $BACKUP_DIR
    fi

    ########################################
    # Create our new directory_name.
    ########################################
    dname=$projectname"-"$version"_"$DIRECTORY_NAME

    ########################################
    # Check out the project.
    ########################################
    echo "Check out tag '$projectname-$version' for '$server'."
    svn export -q $SVN_URI$reponame"/tags/$projectname/"$server"_"$version $WWW_DIR$dname"/"

    ########################################
    # Does the soft link already exists?
    ########################################
    if [ -h $WWW_DIR$projectname ]; then

        ########################################
        # Remove soft link.
        ########################################
        rm $WWW_DIR$projectname
    fi

    ########################################
    # Create new soft link to new directory name.
    ########################################
    echo "Setting up symbolic link."
    ln -s $WWW_DIR$dname"/" $WWW_DIR$projectname

    ########################################
    # Remove old link directory.
    ########################################
    rm -rf $old_link_dir
}


########################################
# Help text.
########################################
########################################
# Usage Example: svncheckout -r webgroup -p w2pc-site -v.196
########################################
function usage
{
    echo "usage: -r [--repo] repository name -p [--project] project name -v [--version] version to check out | [-h help]"
    echo "example: --repo webgroup --project mysite --version 1.0"
}

########################################
# Main
#  Build the query string for svn project.
########################################
while [ "$1" != "" ]; do
    case $1 in
        -r | --repo )           shift; reponame=$1;;
        -p | --project )        shift; projectname=$1;;
        -v | --version )        shift; version=$1
                                runsvn; exit;;
        -h | --help )           usage;;
        * )                     usage
                                exit 1
    esac
    shift
done

