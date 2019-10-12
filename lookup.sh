#!/bin/bash

fn_ns_map() {

cat <<_EOF_

thirdparty:wifi,abc,xyz
dev:micro,foo,bar

_EOF_
}


fn_get_ns() {
 
   if [ $# -eq 1 ]; then 
     fn_ns_map | sed -n "/$1/s/:.*//p"
   fi
}

ns=`fn_get_ns $1`

ns=${ns:-qa}

echo $ns

