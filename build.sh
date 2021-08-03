#!/usr/bin/env bash

set -e

# The usual, add gems etc
docker-compose build

# Followed by copy of Gemfile.lock back to cwd
echo "Copying Gemfile.lock back to repo..."
docker run -it -v $(pwd):/copy_dir imagewrangler cp Gemfile.lock /copy_dir/

echo "Done"

