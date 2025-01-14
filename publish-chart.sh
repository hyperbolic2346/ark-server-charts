#!/bin/sh

[ "$1" = "UPDATE" ] && UPDATE="true"

set -e

function bumpChartVersion() {
  v=$(grep '^version:' ./charts/$1/Chart.yaml | awk -F: '{print $2}' | tr -d ' ')
  patch=${v/*.*./}
  nv=${v/%$patch/}$((patch+1))
  sed -i "" -e "s/version: .*/version: $nv/" charts/$1/Chart.yaml
}

# checkout github-pages
git checkout gh-pages
git pull
git rebase master
git pull
git push

for c in ark-cluster; do
  [ -z "$(git status -s ./charts/$c/Chart.yaml)" -a -z "$UPDATE" ] && bumpChartVersion $c
  (cd charts; helm package $c)
  mv ./charts/$c-*.tgz ./docs/
done

helm repo index ./docs --url https://drpsychick.github.io/ark-server-charts/

git add .
git commit -m "publish charts" -av
git push

# switch back to master and merge
git checkout master
git pull
git merge gh-pages
git push
