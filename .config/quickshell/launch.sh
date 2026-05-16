#!/bin/bash
pgrep -x quickshell > /dev/null && exit 0
exec quickshell
