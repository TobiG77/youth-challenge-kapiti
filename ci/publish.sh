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
    -f or --force: Force publishing

EOT

}

run_update() {

    [ -n "$CI" ] || aws-profile --switch sapient
    aws s3 sync "$SCRIPT_SOURCE_DIR/public" "s3://$PUBLIC_BUCKET"
    git add public
    git commit -m "AS PUBLISHED @ `date +%F-%H-%M`" public
    git push

}

export SCRIPT_SOURCE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )


[ "`type source`" == "source is a shell builtin" ] || abort_on_error "This script is written for Bash!"

OPTS=`getopt -o b:hdf --long bucket:,help,debug,force -n 'parse-options' -- "$@"`

[ $? == 0 ] || abort_on_error "Failed parsing options."

eval set -- $OPTS

FORCE=false

while true; do
  case "$1" in
    -p | --prod ) PROD="true";;
    -h | --help ) print_help ;;
    -d | --debug ) DEBUG=true ;;
    -f | --force ) FORCE=true ;;
    -- ) REMAINING_ARGS="$@" ; break ;;
  esac
  shift
done

[ "$DEBUG" == "true" ] && set -x

if [ "$PROD" == "true" ]
then
    PUBLIC_BUCKET="youth-challenge.kapiti.co"
else
    PUBLIC_BUCKET="preview-yc-2017.kapiti.co"
fi

pushd $SCRIPT_SOURCE_DIR > /dev/null 2>&1

    hugo
    git status --porcelain |grep -q 'M public' ; changed=$?
    [ "$FORCE" == "true" ] ; changed=0
    if [ "$changed" == "0" ]
    then
        echo "Publishing changes"
        run_update
    else
        echo -e "\nNo changes to publish.\n"
    fi

popd > /dev/null 2>&1
