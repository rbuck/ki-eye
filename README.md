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

TBD...

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
