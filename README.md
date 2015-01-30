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

Located in the testing/artifacts directory will be two SSH key
files that you should save or distribute, namely, to your laptop
in particular copy these files to your .ssh directory and chmod
them with a 700 perms setting. Once this has been accomplished
you will be able to log in using the following sort of command:

    ssh -i ~/.ssh/id_rsa_wesson wesson@public.ip.address

## Jump Server Configuration

The first step is to update the jump server by uploading ki-eye
distribution to the $UNAME home directory and uncompressing it.

Following the above step, modify the runit script, changing the
following line to the appropriate nuodb primordial broker host:

    : ${BROKER_HOST:="localhost"}

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
