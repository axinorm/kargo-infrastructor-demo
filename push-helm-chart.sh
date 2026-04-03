#!/bin/bash

cd ./helm
rm -rf .git

git init --initial-branch=main

git config user.name ${GIT_USERNAME}
git config user.email ${GIT_EMAIL}

git add .
git commit -m "feat(all): Init repository"

git remote add origin ${GIT_ORIGIN_URL}
git push origin main -f

cd -
