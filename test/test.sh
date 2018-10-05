#!/bin/bash

set -eu

image=cloudron/basetest

function check_go() {
    if ! docker run $image go version; then
        return 1
    fi
}

function check_node() {
    if ! docker run $image node --version; then
        return 1
    fi
}

check_go
check_node
echo "All tests passed"

