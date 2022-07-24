#!/bin/bash

# rerun if failed unless exited
while : ; do perl -I . l00httpd.pl && break; done
