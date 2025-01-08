#!/usr/bin/env bash
# Batch replace push mirroring setting of all applicable repositories in a GitLab namespace
#
# Copyright 2025 林博仁(Buo-ren Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
GITLAB_PAT='unset'
GITHUB_PAT='unset'
GITLAB_NAMESPACE="${GITLAB_NAMESPACE:-"**UNSET**"}"
GITHUB_NAMESPACE="${GITHUB_NAMESPACE:-"${GITLAB_NAMESPACE}"}"
GITLAB_API_ENDPOINT="${GITLAB_API_ENDPOINT:-https://gitlab.com/api/v4}"

# How many entries per page to request when pagination is required
PAGINATION_ENTRIES="${PAGINATION_ENTRIES:-20}"

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

    # For parsing the curl command's output
    grep
    sed

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

curl_opts_common=(
    --location

    --fail
    --silent
    --show-error
)
curl_opts_gitlab=(
    "${curl_opts_common[@]}"
    --header "PRIVATE-TOKEN: ${GITLAB_PAT}"
)

printf \
    'Info: Determining the type of the "%s" GitLab namespace...\n' \
    "${GITLAB_NAMESPACE}"
if ! namespace_raw="$(
    curl \
        "${curl_opts_gitlab[@]}" \
        "${GITLAB_API_ENDPOINT}/namespaces/${GITLAB_NAMESPACE}"
    )"; then
    printf \
        'Error: Unable to query the namespace information of the "%s" GitLab namespace.\n' \
        "${GITLAB_NAMESPACE}" \
        1>&2
    exit 2
fi

jq_opts=(
    --raw-output
    --exit-status
)
if ! namespace_kind="$(jq "${jq_opts[@]}" .kind <<<"${namespace_raw}")"; then
    printf \
        'Error: Unable to parse out the namespace kind information of the "%s" GitLab namespace from the Namespaces GitLab API response.\n' \
        "${GITLAB_NAMESPACE}" \
        1>&2
    exit 2
fi

case "${namespace_kind}" in
    user)
        printf \
            'Info: The type of the "%s" GitLab namespace is a user.\n' \
            "${GITLAB_NAMESPACE}"
    ;;
    group)
        printf \
            'Info: The type of the "%s" GitLab namespace is a group.\n' \
            "${GITLAB_NAMESPACE}"
    ;;
    *)
        printf \
            'Error: Unable to determine the type of the "%s" GitLab namespace(namespace_kind == "%s").\n' \
            "${GITLAB_NAMESPACE}" \
            "${namespace_kind}" \
            1>&2
        exit 2
    ;;
esac

printf \
    'Info: Querying the list of projects in the "%s" GitLab namespace...' \
    "${GITLAB_NAMESPACE}"
projects=()

case "${namespace_kind}" in
    user)
        for ((page = 1; ; page++)); do
            curl_opts_gitlab_keyset_pagination=(
                "${curl_opts_gitlab[@]}"

                # Write out the Link HTTP response header after the transfer
                --write-out '\n\n%header{link}'
            )

            if test "${page}" -eq 1; then
                users_projects_url="${GITLAB_API_ENDPOINT}/users/${GITLAB_NAMESPACE}/projects?pagination=keyset&order_by=id&sort=asc&per_page=${PAGINATION_ENTRIES}"
            fi

            if ! namespace_projects_raw="$(
                curl \
                    "${curl_opts_gitlab_keyset_pagination[@]}" \
                    "${users_projects_url}"
                )"; then
                printf \
                    'Error: Unable to query the list of projects in the "%s" GitLab namespace.\n' \
                    "${GITLAB_NAMESPACE}" \
                    1>&2
                exit 2
            fi

            sed_opts=(
                # Suppress default behavior of printing pattern space each sed cycle
                -n

                # Only print first line
                --expression='1p'
            )
            if ! namespace_projects_raw_response="$(
                sed "${sed_opts[@]}" <<<"${namespace_projects_raw}"
                )"; then
                printf \
                    'Error: Unable to parse out the Users API raw response from the curl output.\n' \
                    1>&2
                exit 2
            fi

            if ! namespace_projects_lines_raw="$(
                jq --raw-output '.[].path_with_namespace' \
                    <<<"${namespace_projects_raw_response}"
                )"; then
                printf \
                    '\nError: Unable to parse out the project paths of page "%s" of the list of projects in the "%s" GitLab namespace.\n' \
                    "${page}" \
                    "${GITLAB_NAMESPACE}" \
                    1>&2
                exit 2
            fi

            if test -n "${namespace_projects_lines_raw}"; then
                if ! mapfile -t namespace_projects_lines \
                    <<<"${namespace_projects_lines_raw}"; then
                    printf \
                        '\nError: Unable to load the projects lines to the namespace_projects_lines array.\n' \
                        1>&2
                    exit 2
                fi
                projects+=("${namespace_projects_lines[@]}")
            fi

            sed_opts=(
                # Suppress default behavior of printing pattern space each sed cycle
                -n

                # Only print third line
                --expression='3p'
            )
            if ! namespace_projects_raw_link="$(
                sed "${sed_opts[@]}" <<<"${namespace_projects_raw}"
                )"; then
                printf \
                    'Error: Unable to parse out the value of the Link header of the Users API response from the curl output.\n' \
                    1>&2
                exit 2
            fi

            if test -z "${namespace_projects_raw_link}"; then
                break
            fi

            grep_opts=(
                --perl-regexp
                --only-matching
                --regexp='[^<>]+(?=>; rel="next")'
            )
            if ! users_projects_url="$(
                grep "${grep_opts[@]}" <<<"${namespace_projects_raw_link}"
                )"; then
                printf \
                    'Error: Unable to parse out the URL of the next user projects page.\n' \
                    1>&2
                exit 2
            fi
            printf .
        done
        printf '\n'
    ;;
    group)
        # Groups API doesn't support keyset pagination for authenticated users yet, query page count first
        if ! namespace_projects_pages_raw="$(
                curl \
                    --head \
                    "${curl_opts_gitlab[@]}" \
                    "${GITLAB_API_ENDPOINT}/groups/${GITLAB_NAMESPACE}/projects?per_page=${PAGINATION_ENTRIES}"
            )"; then
            printf \
                'Error: Unable to query the Groups API response header of the "%s" GitLab namespace.\n' \
                "${GITLAB_NAMESPACE}" \
                1>&2
            exit 2
        fi

        grep_opts=(
            --perl-regexp
            --regexp='(?<=^x-total-pages: )[[:digit:]]+'
            --only-matching
        )
        if ! namespace_projects_pages="$(grep "${grep_opts[@]}" <<< "${namespace_projects_pages_raw}")"; then
            printf \
                'Error: Unable to query the pagination page count of the "%s" namespace projects.\n' \
                "${GITLAB_NAMESPACE}" \
                1>&2
            exit 2
        fi

        namespace_projects_pages_digits="${#namespace_projects_pages}"
        # Prepare spaces to be backspaced during the first loop iteration
        #      '\([[:digit:]]{digits}/[[:digit:]]{digits}\)'
        printf " %${namespace_projects_pages_digits}s %${namespace_projects_pages_digits}s " ' ' ' '
        progress_report_chars="$((namespace_projects_pages_digits * 2 + 3))"
        for ((page = 1; page <= namespace_projects_pages; page++)); do
            for ((char = 1; char <= progress_report_chars; char++ )); do
                printf '\b'
            done

            printf \
                "(%${namespace_projects_pages_digits}s/%${namespace_projects_pages_digits}s)" \
                "${page}" "${namespace_projects_pages}"
            if ! namespace_projects_raw="$(
                curl \
                    "${curl_opts_gitlab[@]}" \
                    "${GITLAB_API_ENDPOINT}/groups/${GITLAB_NAMESPACE}/projects?page=${page}&per_page=${PAGINATION_ENTRIES}"
                )"; then
                printf \
                    '\nError: Unable to query page "%s" of the list of projects in the "%s" GitLab namespace.\n' \
                    "${page}" \
                    "${GITLAB_NAMESPACE}" \
                    1>&2
                exit 2
            fi

            if ! namespace_projects_lines_raw="$(
                jq --raw-output '.[].path_with_namespace' \
                    <<<"${namespace_projects_raw}"
                )"; then
                printf \
                    '\nError: Unable to parse out the project paths of page "%s" of the list of projects in the "%s" GitLab namespace.\n' \
                    "${page}" \
                    "${GITLAB_NAMESPACE}" \
                    1>&2
                exit 2
            fi

            if ! mapfile -t namespace_projects_lines \
                <<<"${namespace_projects_lines_raw}"; then
                printf \
                    '\nError: Unable to load the projects lines to the namespace_projects_lines array.\n' \
                    1>&2
                exit 2
            fi
            projects+=("${namespace_projects_lines[@]}")
        done
        printf '\n'
    ;;
    *)
        printf \
            'FATAL: Unsupported kind of namespace "%s".\n' \
            "${namespace_kind}" \
            1>&2
        exit 99
    ;;
esac

printf 'Info: Found the following %u projects:\n\n' "${#projects[@]}"

for project in "${projects[@]}"; do
    printf '* %s\n' "${project}"
done
printf '\n'

printf \
    'Info: Operation completed without errors.\n'
