#!/usr/bin/env bash

set -o pipefail
set -o nounset

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
source "${_dir}"/conf-variables.sh

remove_unnecessary_files() {
    cd "${_dir}"/"${_PROJECT_NAME}"
    rm -rf ..?* .[!.]*
    rm ./README.md 2>/dev/null
    rm -r ./test ./logs ./docs 2>/dev/null
}

copy_content() {
    cd "${_dir}"/"${_PROJECT_NAME}"
    cp -r "${_dir}"/../source "${_dir}"/"${_PROJECT_NAME}"
    cp -r "${_dir}"/../deploy "${_dir}"/"${_PROJECT_NAME}"
    cp "${_dir}"/../user-config.sh "${_dir}"/"${_PROJECT_NAME}"
}

delete_content() {
    remove_unnecessary_files
}

create_content() {
    cd "${_dir}"/"${_PROJECT_NAME}"
    # Nothing to do here
}

create_deployment() {
    rm -rf "${_dir}"/"${_PROJECT_NAME}" "${_dir}"/"${_DEPLOYMENT_NAME}" "${_dir}"/*.tar.gz "${_dir}"/../"${_DEPLOYMENT_DIR}"/*.tar.gz
    mkdir "${_dir}"/"${_PROJECT_NAME}"
    copy_content
    delete_content
    create_content
    mv "${_dir}"/"${_PROJECT_NAME}" "${_dir}"/"${_DEPLOYMENT_NAME}"
    cd "${_dir}"
    tar -zcf "${_DEPLOYMENT_NAME}-${_DEPLOYMENT_VERSION}".tar.gz "${_DEPLOYMENT_NAME}"
    mv "${_dir}"/*.tar.gz "${_dir}"/../"${_DEPLOYMENT_DIR}"/
    rm -rf "${_dir}"/"${_DEPLOYMENT_NAME}"
}

main() {
    cd "${_dir}"/..
    git status --porcelain | grep -q '^' &&
        echo "You have files that is not commited, check your git status!" || {
        echo "$(git status)" | grep -qw "Your branch is up to date with 'origin/master'." ||
            echo "Code is not up to-date, check your git status!" && {
            create_deployment
        }
    }
}

main "$@"