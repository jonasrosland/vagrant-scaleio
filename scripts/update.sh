#!/bin/bash

case "$(uname -r)" in
  *el6*)
    yum -y update
    ;;
  *el7*)
    yum -y update
    ;;
esac
