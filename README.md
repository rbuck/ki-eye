# Introduction

Tools to manage and reconfigure mock multi-region environments
and failure scenarios for several concurrent users.

## Requirements

There are a few fundamental requirements to use this infrastructure:

- root access
- password-less login
- remote password-less ssh exec
- multiple subnets (one for each mock region)
- one special host acting as a jump server on its own subnet

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

### Starting a Pre Canned Archive

Deploy a canned database archive to the archive host.
Verify permissions are correct:

    sudo chown -R nuodb:nuodb /var/opt/nuodb/production-archives/dbname



### Starting a Fresh Archive

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
