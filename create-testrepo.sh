#!/bin/bash
project_root_path=$(git rev-parse --show-toplevel)
test_repo_path=$(mktemp -d)
ln -sf "$test_repo_path" "${project_root_path}/testrepo"
git init "${project_root_path}/testrepo"
cd "${project_root_path}/testrepo"
echo foo > foo
git add foo
git commit -m 'add foo'
echo bar > bar
git add bar
echo baz > baz
echo foofoo > foo
