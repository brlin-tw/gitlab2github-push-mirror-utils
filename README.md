# replace-gitlab-push-mirror-settings

Batch replace GitLab push mirror settings for all repositories in a namespace.

<https://gitlab.com/brlin/replace-gitlab-push-mirror-settings>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/brlin/replace-gitlab-push-mirror-settings/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/brlin/replace-gitlab-push-mirror-settings/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/brlin-tw/replace-gitlab-push-mirror-settings/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/brlin-tw/replace-gitlab-push-mirror-settings/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/brlin/replace-gitlab-push-mirror-settings "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/brlin/replace-gitlab-push-mirror-settings)

## Prerequisites

The following prerequisites must be met in order to use this product:

* The host running the utility must have Internet access.
* The host running the utility must have the following software installed and its commands to be available in your command search PATHs:
    + curl  
      For interacting with GitLab and GitHub's API.
    + grep  
      sed  
      For parsing the curl command's output.
    + jq  
      For parsing the JSON response of GitLab and GitHub's API.

## Environment variables that can change the utility's behaviors

The following environment variables can be used to change the utility's behaviors according to your needs:

### GITLAB_NAMESPACE

GitLab namespace to replace push mirroring settings, currently namespaces including subgroup is not supported.

### GITHUB_NAMESPACE

GitHub namespace to configure push mirroring to.

### GITLAB_API_ENDPOINT

The GitLab REST API v4-compatible endpoint to use.

**Default value:** `https://gitlab.com/api/v4`

### GITHUB_API_ENDPOINT

The GitHub API v2022-11-28-compatible endpoint to use.

**Default value:** `https://api.github.com`

## Header variables that can change the utility's behaviors

The following variables can be used to change the utility's behaviors, however they can only be set by directly editing the header portion of the utility script due to sensitive nature:

### GITLAB_PAT

The personal access token with access to the GitLab namespace.  *REQUIRED.*

**Default value:** (unset)

### GITHUB_PAT

The personal access token with access to the GitHub namespace.  This can be use to mitigate GitHub rate limiting.  *OPTIONAL.*

**Default value:** (unset)

Required permission: Repository permissions > Metadata (Read-only).

## Logic

The following documents the logic of this utility in operation:

1. A list of all GitLab projects in a namespace is queried via GitLab's REST API.
1. For each GitLab project:
    1. Determine the URL of the corresponding GitHub project(repository).
    1. Check whether the GitHub project actually exists.
    1. If the project exists in the specified GitHub namespace, check whether the GitLab project has an repository mirroring configuration against it.
    1. If the repository mirroring configuration exists, remove the configuration.
    1. Create a new repository mirroring configuration with the updated GitHub PAT.

## References

The following materials are referenced during the development of this project:

* [REST API | GitLab](https://docs.gitlab.com/ee/api/rest/)  
  Explains:
    + The basic usage of the GitLab REST API.
    + How to do pagination.
* [REST API authentication | GitLab](https://docs.gitlab.com/ee/api/rest/authentication.html)  
  Explains how to authenticate the user when using the GitLab REST API.
* [Store and reuse values using variables | Postman Learning Center](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-variables)  
  Explains how to define secret
* curl(1) manpage  
  Explains the usage of the `--header` option.
* [Escape sequences - IBM Documentation](https://www.ibm.com/docs/en/i/7.3?topic=set-escape-sequences)  
  Explains the escape sequence of the backspace control character.
* [List projects | Groups API | GitLab](https://docs.gitlab.com/ee/api/groups.html#list-projects)  
  Explains how to query all projects in a user-specified group.
* [List a user’s projects | Projects API | GitLab](https://docs.gitlab.com/ee/api/projects.html#list-a-users-projects)  
  Explains how to query all projects in a user-specified user.
* [Getting started with the REST API - GitHub Docs](https://docs.github.com/en/rest/using-the-rest-api/getting-started-with-the-rest-api)  
  Explains the basic usage of the GitHub REST API.
* [Authenticating to the REST API - GitHub Docs](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api#about-authentication)  
  Explains how to do authentication using the GitHub REST API.
* [Get a repository - REST API endpoints for repositories - GitHub Docs](https://docs.github.com/en/rest/repos/repos#get-a-repository)  
  Explains how to query the information of a certain repository using the GitHub REST API.
* [Tutorial | jq](https://jqlang.github.io/jq/tutorial/)  
  Explains the basic usage of jq.

## Licensing

Unless otherwise noted(individual file's header/[REUSE.toml](REUSE.toml)), this product is licensed under [the 3.0 version of the GNU Affero General Public License license](https://www.gnu.org/licenses/agpl-3.0.en.html), or any of its recent versions you would prefer.

This work complies to [the REUSE Specification](https://reuse.software/spec/), refer to the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
