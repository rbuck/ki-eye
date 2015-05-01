# ki eye

[<img src="https://travis-ci.org/rbuck/ki-eye.svg?branch=master" alt="Build Status" />](http://travis-ci.org/rbuck/ki-eye)

# Introduction

Tools to manage and reconfigure mock multi-region environments
and failure scenarios for several concurrent users.

## Prerequisites

There are a few fundamental requirements to use this infrastructure:

- root access
- password-less login
- remote password-less ssh exec
- multiple subnets (one for each mock region)
- one special host acting as a jump server on its own subnet

CentOS does not include mkpasswd; despite claims online that mkpasswd is
also available via the 'expect' package, this is wholy untrue; the tool
in the 'expect' package is completely different, is woefully incomplete,
and lacks parity with other platforms. As such we have taken to write our
own tool to do this so we have parity across platforms. This script must
be deployed to all hosts:

    HOST_FILE=hosts.all ./foreachhost ./userman deploy_crypt

### Setting Root Permissions for the Admin Account

The admin that is used to create other accounts (per customer) must
have these permissions set in the /etc/sudoers file:

    urename ALL=(ALL) NOPASSWD: ALL

### Enable Remote SSH Exec:

To execute remote sudo commands you will have to disable the requirement
to have a TTY. Edit the /etc/sudoers file and comment out this line if
it is present:

    #Defaults    requiretty

### Enable Passwordless Login

Create a secure SSH key, but do not set a passphrase:

    ssh-keygen -t rsa -b 1024

Then cat the public keyfile into the authorized keys file:

    cat id_rsa.pub >> authorized_keys

Lastly, set the permissions of the SSH files:

    chmod 700 id_rsa*

## Central Tenets

### Hosts File Driven

The scripts herein are optionally driven by hosts files, allowing
for-each semantics for each listed. Two components of this design
are the:

- hosts file
- foreachhost script

#### Host File Format

The format of the hosts file is CSV-based, and its schema is as follows:

    region,role,ipaddr,usejrnldir,peeraddr

The region is a convenient name for the region to which the related
host is part of; these are free-form character fields, generally has
the traditional naming conventions:

- one, two, tre
- east, west
- amer, emea, apac
- etc...

The role field is a discriminator frequently used to distinguish
hosts having special disk capabilities from those that are compute
oriented; generally the names used herein are:

- SM    : NuoDB Storage Manager Node
- TE    : NuoDB Transaction Engine Node
- JS    : Jump Server

The ipaddr field is the private ip address for the host, or DNS resolvable
host name.

The usejrnldir field indicates that a separate SSD exists on the host
that may be used. The field is a boolean field, 0 for false, 1 for true.

The peeraddr field is used to set NuoDB peering and indicates to which
host ip addr this NuoDB node should peer to. The primordial broker has
this set to empty.

#### ForEachHost Script Semantics

The general execution model for the foreachhost script is as follows:

    [HOST_FILE=hosts.all : hosts (default)] [ENV_VAR_1=value1] ./foreachhost \
        [ENV_VAR_2=value2]* ./{sub-script-name} {sub-script-options-or-command}

One key observation here, you can override which host file is used by
the foreachhost script via the HOST_FILE environment variable, but this
defaults to a hosts file named 'hosts'.

The foreachhost script sets additional environment variables useable
by the sub-script:

- HOST_FILE=${HOST_FILE}
- TARGET_HOST=${ipaddr}
- TARGET_ROLE=${role}
- TARGET_REGION=${region}
- USE_JOURNAL_DIR=${usejrnldir}
- PEER_ADDRESS=${peeraddr}

## User Account Provisioning

Tools exist for provisioning user accounts and identical credentials
on multiple hosts. The overall process is:

    ./userman salt # note output salt value, use below...
    UNAME=wesson ./userman create_key
    HOST_FILE=hosts.all ./foreachhost UNAME=wesson SALT=feFedf! PASSWD=aZVG85ndv9CK8yE ./userman add
    HOST_FILE=hosts.all ./foreachhost UNAME=wesson ./userman add_sudo

Located in the testing/artifacts directory will be two SSH key
files that you should save or distribute, namely, to your laptop
in particular copy these files to your .ssh directory and chmod
them with a 700 perms setting. Once this has been accomplished
you will be able to log in using the following sort of command:

    ssh -i ~/.ssh/id_rsa_wesson wesson@jump.server.ip.address

## Jump Server Configuration

The next step is to update the jump server by uploading the ki-eye
distribution to the $UNAME home directory and uncompressing it.

Following the above step, modify the runit script, changing the
following line to the appropriate nuodb primordial broker host:

    : ${BROKER_HOST:="localhost"}

## Network Verification

Before running a test be sure to check your network for saneness.
This is accomplished by running the netcheck script:

    HOST_FILE=hosts.all ./foreachhost ./netcheck

Output will be of the form:

    p111,10.3.89.2,0.023/0.006
    p112,10.3.89.2,0.019/0.006
    p113,10.3.89.2,0.019/0.005
    p114,10.3.89.2,0.019/0.006
    p115,10.3.89.2,0.019/0.004
    ...

The output format above is:

    target-host,source-host,mean-rtt/std-dev

## Database Provisioning

First step is to update runit bash variable database credentials:

    : ${BROKER_HOST:="localhost"}
    : ${DATABASE_NAME:="dbname"}
    : ${DATABASE_SCHEMA="test"}
    : ${DATABASE_USER:="dba"}
    : ${DATABASE_PASSWORD="dba"}

Then for each test (scale out or geo distribution) scenario create
an appropriate hosts file. Just as an initial step create one host
file named host.0 with only one TE and one SM in region_one so we
can perform a basic database test to verify settings.

    cp hosts.region_one hosts.0

Then comment out all hosts except the first two in region_one.

### Starting a Storage Manager with a Pre Canned Archive

Deploy a canned database archive to the archive host.
Verify permissions are correct:

    sudo chown -R nuodb:nuodb /var/opt/nuodb/production-archives/dbname

Make sure all SM hosts have this archive in place.

Then start up the storage engine:

    HOST_FILE=hosts.dr ./foreachhost ./runit startsm

### Starting a Storage Manager with a Fresh Archive

Modify the runit script and validate the memory, database and
schema names, the username and password, are all correct.

To start your storage engines, picking your intended hosts
file:

    HOST_FILE=hosts.dr ./foreachhost FORCE_INIT=1 ./runit startsm

Note: the FORCE_INIT flag tells the script to supply the initialize=yes
flag to Nuo, as well as makes sure there are no existing archives
in the target location.

### Starting the Transaction Engines

Modify the runit script and validate the memory, database and
schema names, the username and password, are all correct.

To start your transaction engines, picking your intended hosts
file:

    HOST_FILE=hosts.dr ./foreachhost ./runit startte

## Traffic Shaping

For partitioning or delay, see the shape script and its wrappers.

### Partitioning

The partitioning capability uses IPtables to block traffic w/o
cleanly closing sockets as to simulate a WAN level event. The
files presently are set up around the use of different subnets
for each "region". We use subnet notation w/ IPtables to tell
each side of a region boundary to drop all traffic bound for
the other subnet.

### Delay

Delay, like partitioning, uses subnets to conveniently test
high latency configurations. However, to add delay we use TC.
The scripts can be configured to use a normal distribution
and it works fantastic, but the jitter CANNOT be zero, therefore
if you find yourself needing to use JITTER or normal distributions,
uncomment the rather obvious like currently commented out,
and comment out the current line.

## Using Screen

Linux (and Mac) have a utility available called screen which is
very helpful, if for no other reason than to make sure jobs are
not killed when you close up your laptop and the SSH session
hangs up. Other reasons this is useful is support for virtual
terminals.

Here we share some of the common commands you will use with screen.

### Installing Screen with Yum

    # yum install screen

### Starting Screen

Screen is started from the command line just like any other,
and you can create a convenient session name to refer to it
later by:

    # screen -S thename

### Control Command

Screen uses the command “Ctrl-a” that’s the control key and a
lowercase “a”  as a signal to send commands to screen instead
of the shell.

For example, “Ctrl-a” then “?”. You should now have the screen
help page.

### Creating Windows

Command: “Ctrl-a” “c”.

To create a new window, you just use “Ctrl-a” “c”.

This will create a new window for you with your default prompt.
Your old window is still active.

For example, I can be running top and then open a new window
to do other things. Top stays running! It is still there. To
try this for yourself, start up screen and then run top.
(Note: I have truncated some screens to save space.)

Your top window is still running you just have to switch back
to it.

### Switching Between Windows: Next and Previous

Command: “Ctrl-a” “n”  OR  “Ctrl-a” “p”

Screen allows you to move forward and back. In the example above,
you could use “Ctrl-a “n” to get back to top. This command
switches you to the next window.

The windows work like a carousel and will loop back around
to your first window.

You can create several windows and toggle through them with
“Ctrl-a” “n” for the next window or “Ctrl-a” “p” for the
previous window.

Each process will keep running until you kill that window.

### Switching Between Windows: Numbered Windows

Command: “Ctrl-a” {0-9}

Screen allows you to select the window to display, as it
numerically assigns ordinals to each screen, starting with
0 and proceeding to 9. You can directly go to a numbered
window by doing something like “Ctrl-a” “5”.

### Detaching From Screen

Command: “Ctrl-a” “d”

Detaching is the most powerful part of screen.  Screen allows
you to detach from a window and reattach later.

If your network connection fails, screen will automatically
detach your session!

You can detach from the window using “Ctrl-a” “d”.

This will drop you into your shell.

If your network connection fails, screen will automatically
detach your session!

All screen windows are still there and you can re-attach to
them later.

### Reattach to Screen

Command: screen -r

If your connection drops or you have detached from a screen,
you can re-attach by just running:

    $ screen -r

This will re-attach to your screen.

However, if you have multiple screens you may get this:

    $ screen -r
    There are several suitable screens on:
    31917.pts-5.office      (Detached)
    31844.pts-0.office      (Detached)

To re-attach to one of those simply issue a command like:

    screen -r  31844.pts-0.office

### Listing Screen Sessions

Command: screen -ls

If you happen to be using named screen sessions you can simply
provide the convenience name as an argument to the reattach
command.

    $ screen -r sessionname

To recall those session names however, as well as to check to
verify a previously created session still exists you may run
this command:

    $ screen -ls
