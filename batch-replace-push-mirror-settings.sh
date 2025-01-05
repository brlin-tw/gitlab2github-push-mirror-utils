#!/usr/bin/env bash
# Batch replace push mirroring setting of all applicable repositories in a GitLab namespace
#
# Copyright 2025 林博仁(Buo-ren Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
GITLAB_PAT='unset'
GITHUB_PAT='unset'
GITLAB_NAMESPACE="${GITLAB_NAMESPACE:-"**UNSET**"}"
GITHUB_NAMESPACE="${GITHUB_NAMESPACE:-"${GITLAB_NAMESPACE}"}"
GITLAB_HOST="${GITLAB_HOST:-gitlab.com}"

printf \
    'Info: Configuring the defensive interpreter behaviors...\n'
set_opts=(
    # Terminate script execution when an unhandled error occurs
    -o errexit
    -o errtrace

    # Terminate script execution when an unset parameter variable is
    # referenced
    -o nounset
)
if ! set "${set_opts[@]}"; then
    printf \
        'Error: Unable to configure the defensive interpreter behaviors.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking the existence of the required commands...\n'
required_commands=(
    curl
    jq
    realpath
)
flag_required_command_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        flag_required_command_check_failed=true
        printf \
            'Error: This program requires the "%s" command to be available in your command search PATHs.\n' \
            "${command}" \
            1>&2
    fi
done
if test "${flag_required_command_check_failed}" == true; then
    printf \
        'Error: Required command check failed, please check your installation.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Configuring the convenience variables...\n'
if test -v BASH_SOURCE; then
    # Convenience variables may not need to be referenced
    # shellcheck disable=SC2034
    {
        printf \
            'Info: Determining the absolute path of the program...\n'
        if ! script="$(
            realpath \
                --strip \
                "${BASH_SOURCE[0]}"
            )"; then
            printf \
                'Error: Unable to determine the absolute path of the program.\n' \
                1>&2
            exit 1
        fi
        script_dir="${script%/*}"
        script_filename="${script##*/}"
        script_name="${script_filename%%.*}"
    }
fi
# Convenience variables may not need to be referenced
# shellcheck disable=SC2034
{
    script_basecommand="${0}"
    script_args=("${@}")
}

printf \
    'Info: Setting the ERR trap...\n'
trap_err(){
    printf \
        'Error: The program prematurely terminated due to an unhandled error.\n' \
        1>&2
    exit 99
}
if ! trap trap_err ERR; then
    printf \
        'Error: Unable to set the ERR trap.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking the runtime parameters of the program...\n'
if test "${GITLAB_PAT}" = unset; then
    printf \
        'Error: The GITLAB_PAT parameter is not set.\n' \
        1>&2
    exit 1
fi

if test "${GITLAB_PAT#glpat-}" = "${GITLAB_PAT}"; then
    printf \
        'Error: The specified value of the GITLAB_PAT parameter is invalid.\n' \
        1>&2
    exit 1
fi

if test "${GITHUB_PAT}" != unset \
    && test "${GITHUB_PAT#github_pat_}" = "${GITHUB_PAT}"; then
    printf \
        'Error: The specified value of the GITHUB_PAT parameter is invalid.\n' \
        1>&2
    exit 1
fi

if test "${GITLAB_NAMESPACE}" == '**UNSET**'; then
    printf \
        'Error: The GITLAB_NAMESPACE environment variable must be set.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Operation completed without errors.\n'
