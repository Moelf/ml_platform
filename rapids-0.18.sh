#!/bin/sh
[ -f "\$ROOTsetupPy37" ] && . "\$ROOTsetupPy37"
exec /opt/anaconda3/envs/rapids-0.18/bin/python3 \$@
