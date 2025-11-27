#!/usr/bin/env bash

set -e

echo "Building dev/test environment ..."

if [ -f Gemfile.lock ]; then
  rm Gemfile.lock
fi

docker-compose build

echo "Copying Gemfile.lock back to repo..."

docker run -it -v $(pwd):/copy_dir imagewrangler cp Gemfile.lock /copy_dir/

echo "Done"
