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
    + jq  
      For parsing the JSON response of GitLab and GitHub's API.

## Environment variables that can change the utility's behaviors

The following environment variables can be used to change the utility's behaviors according to your needs:

### GITLAB_NAMESPACE

GitLab namespace to replace push mirroring settings, currently namespaces including subgroup is not supported.

### GITHUB_NAMESPACE

GitHub namespace to configure push mirroring to.

## References

To be addressed.

## Licensing

Unless otherwise noted(individual file's header/[REUSE.toml](REUSE.toml)), this product is licensed under [the 3.0 version of the GNU Affero General Public License license](https://www.gnu.org/licenses/agpl-3.0.en.html), or any of its recent versions you would prefer.

This work complies to [the REUSE Specification](https://reuse.software/spec/), refer to the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
