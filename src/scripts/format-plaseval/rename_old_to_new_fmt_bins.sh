#!/usr/bin/env bash
# ---------------------------------------------------------------------------- #
# Rename old to new format bins
#
# Old format: <sample_uid>.<method_code>.tsv
# New format: <sample_uid>.tsv
# ---------------------------------------------------------------------------- #

dir=$1
meth_code=$2

function usage {
    echo "Usage: $0 DIRECTORY METHOD_CODE"
}

if [ ! -d "$dir" ]; then
    echo "ERROR: $dir does not exist" >&2
    exit 1
fi

if [ -z "$meth_code" ]; then
    echo "ERROR: missing method code" >&2
    exit 1
fi

cd "$dir" || exit 1

for f in *."$meth_code".tsv; do
    mv -n -- "$f" "${f%."$meth_code".tsv}.tsv"
done
