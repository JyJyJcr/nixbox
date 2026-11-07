#!/bin/bash

for var in $(compgen -v NIXBOX_RECOVER_); do
    new_var=${var#NIXBOX_RECOVER_}
    if [[ -v $var ]]; then
        printf -v "$new_var" '%s' "${!var}"
        export "$new_var"
    fi
    unset "$var"
done
unset PROMPT_COMMAND

exec "$@"
