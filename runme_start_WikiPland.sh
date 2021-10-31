#!/bin/bash

# rerun if failed unless exited
while perl -I . l00httpd.pl || [[ $? -ne 1 ]] ; do sleep 1 ; done
