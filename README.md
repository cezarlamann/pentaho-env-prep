# pentaho-env-prep
# Pentaho BI Server CE Environment Preparation Scripts 

The goal of this project is to create one or more scripts to automate Pentaho BI Server setups on cloud/on-premises servers where docker is not available. Softwares involved: Pentaho BI Server CE 6, PostgreSQL 9.4, Java 8 (OpenJDK 8) and inherited dependencies.

Most of this work is based on, and harness some scripts from SeraSoft docker-pentaho repository (https://github.com/SeraSoft/docker-pentaho) which is cloned by me too.

## How it works?

- You must have a broadband connection, since the size of all softwares involved in this project is around 1.5 Gb.
- This script is aimed at Debian-like (mainly Ubuntu) distros, since it uses `apt-get` to install packages. It could be refactored to fit another Linux distributions.
- You must have `root` rights. If not, you MUST have rights to edit `/etc/init.d/` files, to update the Linux Init system and install packages, at least.

## Usage

### "`sudo sh install-script.sh`" or "`su -c "sh install-script.sh"`" (without quotes)

## Remarks

- This is a Work In Progress, so there is a lot of things to do yet.
- This script installs PostgreSQL 9.4, setting "`postgres`" user with a "`postgres`" password
- This script opens all subnet ports and puts PostgreSQL to listen to everything (`pg_hba.conf` and `postgresql.conf` files). **YOU MUST HARDEN SECURITY AND CONFIGURE IT PROPERLY TO SUIT YOUR NEEDS**
