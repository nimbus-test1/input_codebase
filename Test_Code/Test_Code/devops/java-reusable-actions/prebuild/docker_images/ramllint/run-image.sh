#!/bin/sh

if [[ $# -ne 1 ]]; then
	echo "Must provide RAML file as a parameter to be passed to ramllint" >&2
	exit 2
fi

echo "$1"

docker run -v "$(pwd)":/home/node/ramllint ramllint /home/node/ramllint/"$1"