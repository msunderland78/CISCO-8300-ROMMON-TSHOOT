#!/bin/bash
# Keep the observer a child of the service session leader: opening the serial
# device must not make the observer itself its controlling-terminal leader.
[[ ${1:-} == --live ]] || { echo 'Plan only: C8235-A observer launcher'; exit 0; }
[[ ${2:-} == --confirmed-chassis && ${3:-} == FGL2835L42B ]] || exit 1
/bin/bash /c8235-psu-observe.sh "$@"
result=$?
exit "$result"
