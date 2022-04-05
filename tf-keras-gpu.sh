#!/bin/sh
[ -f "\$ROOTsetupPy37" ] && . "\$ROOTsetupPy37"
exec /opt/anaconda3/envs/tf-keras-gpu/bin/python3 \$@
