#!/bin/bash
#
# Variables used by the STARS client scripts.
#
# NOTE: All paths should be given as absolute paths, not relative paths.

# RHOST
#
# If the STARS management node is a remote machine, use this to specify the
# user/host.
#
# Examples:
#    # Remote host
#    export RHOST=user@remote-host
#	 # Local host
#    export RHOST=

# SPATH
#
# Location of the STARS source (i.e., your copy of the git repo).
#
# For example:
#    export SPATH=/path/to/stars

# DPATH
#
# Location of the deployed stars code on each node in the cluster.
#
# For example:
#     export DPATH=/path/to/stars-deployment
