#!/usr/bin/env bash

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_folder="$(cd "${_dir}/.." && pwd)"

install_prerequisite_centos() {
    echo "install_prerequisite_centos"
    sudo yum update -y
    sudo yum install -y curl grep bc
}

install_prerequisite_debian() {
    echo "install_prerequisite_debian"
    sudo apt update
    sleep 5
    sudo apt install -y curl grep bc
}

# this only made to cater for centos7 and ubuntu18
main() {
    hostnamectl | grep -qi centos && install_prerequisite_centos || install_prerequisite_debian
    sudo chmod ugo+rw "${_home_folder}"/*.sh
    sudo chmod +x "${_dir}"/*.sh 
}

main "$@"
