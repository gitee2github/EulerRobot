#!/bin/bash

cd "$(dirname "$0")"
cp -r ../* ${LKP_SRC:?}/
grep "virttest::" ${LKP_SRC:?}/distro/adaptation-pkg/openeuler || echo "virttest::" >> ${LKP_SRC:?}/distro/adaptation-pkg/openeuler
