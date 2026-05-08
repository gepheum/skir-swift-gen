#!/bin/bash

set -e

export GITHUB_TOKEN=""

npm i
npm run lint:fix
npm run format
npm run build
npm run test
