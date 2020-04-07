#!/usr/bin/bash

set -ex

rm -rf ./public/*

hugo

cd public && git add . && git commit -m "update blog" && git push && cd ..  
