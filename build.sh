#!/usr/bin/env bash

set -e

echo "Building dev/test environment ..."

rm Gemfile.lock

docker-compose build

echo "Copying Gemfile.lock back to repo..."

docker run -it -v $(pwd):/copy_dir imagewrangler cp Gemfile.lock /copy_dir/

echo "Done"
