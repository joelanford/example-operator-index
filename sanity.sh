#!/usr/bin/env bash
#  PNAME=$$(bin/yq "select(.schema == \"olm.package\") | .name" catalog/$(OPERATOR_NAME)/catalog.yaml)
#  @echo `bin/yq "select(.schema == \"olm.package\") | .name" catalog/$(OPERATOR_NAME)/catalog.yaml`
#  @export PNAME=$(shell bin/yq "select(.schema == \"olm.package\") | .name" catalog/$(OPERATOR_NAME)/catalog.yaml)
#  @echo package name is $(PNAME)
#  @if [ ${PNAME} != ${OPERATOR_NAME} ] \ 
#  then \ 
#  $(error "operator name in veneer and Makefile does not agree: Makefile(${OPERATOR_NAME}) Veneer:(${PNAME})") 
#  fi

function usage () {
  echo "usage: $0 -n package-name -f veneer-file-name"
  exit 1
}

function logit() {
    if [ $QUIET_MODE -eq 0 ]; then
        echo $1
    fi
}

YQ=bin/yq
QUIET_MODE=0

while getopts 'n:f:q' arg; 
do
  case "$arg" in
    f) FILENAME=$OPTARG ;;
    n) PKGNAME=$OPTARG ;;
    q) QUIET_MODE=1 ;;
    h) usage ;; 
  esac
done
shift `expr $OPTIND - 1`

#echo "FILENAME is $FILENAME"
#echo "PKGNAME is $PKGNAME"

if [ -z $FILENAME ]
then
  logit "veneer-file-name is empty"
  usage
fi

if [ ! -e $FILENAME ]
then
  logit "$FILENAME does not exist"
  exit 253
fi

if [ -z $PKGNAME ]
then
  logit "package-name is empty"
  usage
fi

if [ ! -e $YQ ]
then
  logit "unable to find yq binary: $YQ"
  exit 255
fi

SCHEMA_PNAME=$($YQ "select(.schema == \"olm.package\") | .name" ${FILENAME})
if [ $SCHEMA_PNAME != $PKGNAME ] 
then
  logit "operator name in catalog and Makefile do not agree:"
  logit "    Makefile(${SCHEMA_PNAME})"
  logit "    catalog (${PKGNAME})"
  exit 254
else
  logit "operator name match between catalog and Makefile"
fi


