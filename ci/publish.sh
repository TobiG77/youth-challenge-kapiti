#!/usr/bin/env bash

abort_on_error() {
  echo -e "$1" 1>&2
  exit 1
}

print_help() {

cat <<-EOT

    -h or --help : Prints this help
    -p or --prod : Deploy to production
    -d or --debug: Debug script

EOT

}

run_update() {

    aws-profile --switch sapient
    aws s3 sync "$SCRIPT_SOURCE_DIR/public" "s3://$PUBLIC_BUCKET"
    git commit -m "AS PUBLISHED @ `date +F-%H-%M`" public
    git push

}

export SCRIPT_SOURCE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )


[ "`type source`" == "source is a shell builtin" ] || abort_on_error "This script is written for Bash!"

OPTS=`getopt -o b:hd --long bucket:,help,debug -n 'parse-options' -- "$@"`

[ $? == 0 ] || abort_on_error "Failed parsing options."

eval set -- $OPTS

while true; do
  case "$1" in
    -p | --prod ) PROD="true";;
    -h | --help ) print_help ;;
    -d | --debug ) DEBUG=true ;;
    -- ) REMAINING_ARGS="$@" ; break ;;
  esac
  shift
done

[ "$DEBUG" == "true" ] && set -x

if [ "$PROD" == "true" ]
then
    PUBLIC_BUCKET="kapiti-digital-youth-challenge-2017"
else
    PUBLIC_BUCKET="kapiti-digital-youth-challenge-2017.kapiti.co"
fi

pushd $SCRIPT_SOURCE_DIR > /dev/null 2>&1

    hugo
    git status --porcelain |grep -q 'M public' ; changed=$?
    if [ "$changed" == "0" ]
    then
        echo "Publishing changes"
        run_update
    else
        echo -e "\nNo changes to publish.\n"
    fi

popd > /dev/null 2>&1
