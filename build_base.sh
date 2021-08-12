#!/usr/bin/env bash

set -e

echo "Building base image for dev/test environment ..."

docker build -f Dockerfile.base . -t imagewrangler_base

echo "Done"
