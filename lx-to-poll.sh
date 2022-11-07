#!/bin/bash
SERVER="http://smisdev.sherwin.com/polling" #Default to dev

N=`tput sgr0`
B=`tput bold`
BG=`tput smso`
AFLAG=false
FFLAG=false
SFLAG=false
BATCH="deferred"
declare -a APPS=("UPD" "PhoenixC" "CUPN" "STORE" "PARAM" "Volume" "XCDS" "APPS" "QCDS" "DXGROUP" "EDIACCT" "EDIACCT" "CUST" "MSAVEND" "SizeCodeMaintenance" "MfgMaintenance" "Cust" "PRICE-1.0" "PRICE-2.0" "ProductMaintenance" "storeStaffing" "SYSCTL" "TinterVersion" "DNRETURN")

contains (){
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

usage ()
{
  echo -e \\n"Usage Documentation for ${B}$0.${N}"
  echo -e "${B}The following command line switches indicate the environment${N}"
  echo "${BG}-p${N}  --Sets Production"
  echo "${BG}-q${N}  --Sets QA"
  echo "${BG}-d${N}  --Sets Development *Default"
  echo -e "${B}Required parameters${N}"
  echo "${BG}-a${N}  --Sets the application name"
  echo "${BG}-f${N}  --Sets the file name.  Repeatable for multiple files"
  echo "${BG}-s${N}  --Sets the store list, comma delimited or filename with comma delimted"

  echo -e "${B}Optional parameters${N}"
  echo "${BG}-x${N}  --Expires, integer, number of days from today"
  echo "${BG}-t${N}  --Run After Date, date format YYYY-MM-DD."
  echo "${BG}-r${N}  --Prerequisite"
  echo "${BG}-e${N}  --Request to fix works with Fix Option"
  echo "${BG}-o${N}  --Fix Option: rescind, replace, prereq, equivalent_to"
  echo "------------------------------------------------------------------"
  echo "-help  --Displays this help                                          "
  echo "Example : ${B}$0 -q -a SYSCTL -f updt-sysctl.xml -s 9959,9953${N}" 1>&2
  exit 1
}


if [ "$#" -eq 0 ]
then
  usage
fi

while getopts ":dqpa:f:s:h:x:t:r:e:o:" opt; do
  case $opt in 
    d) 
      SERVER="https://smisdev.sherwin.com/polling"
      ;;
    q)
      SERVER="https://smisqa.sherwin.com/polling"
      ;;
    p) 
      SERVER="https://smis.sherwin.com/polling"
      ;;
    a) 
      AFLAG=true;APP_NM=${OPTARG}
      ;;
    f)
      FFLAG=true;FILE_NM+=(${OPTARG})
      ;;
    s)
      SFLAG=true;STORES=${OPTARG}
      ;;
    x)
      EXPIRES=${OPTARG}
      ;;
    t)
      AFTERDATE=${OPTARG}
      ;;
    r)
      PREREQ=${OPTARG}
      ;;
    e)
      REQTOFIX=${OPTARG}
      ;;
    o)
      FIXOPTION=${OPTARG}
      ;;
    h)
      usage
      ;;
    \?)
      echo -e \\n"Option -${B}$OPTARG${N} not allowed"
      echo
      echo usage
      ;;
     :) 
      echo "Missing option argument for -${B}$OPTARG${N}"
      exit 2
      ;;
   esac
done 
shift $(( OPTIND -1 ))

if [[ -f $STORES ]]; then
   #This is a file to read in for data
   STORES=$(<$STORES)
fi


#apply string formatting for store list.
STORES=$(echo $STORES | sed -e 's/^/"/' -e 's/$/"/' -e 's/,/","/g')

#Validate the application name
contains "$APP_NM" "${APPS[@]}"
if [ "$?" -eq "1" ]; then
  echo "Invalid App: ${B}$APP_NM${N}"
  echo "Valid Apps are:"
  echo ${B}${APPS[@]}${N}
  exit
fi

#Validate require parms were set
if ! $AFLAG; then
   echo "Require parameter ${B}-a${N} missing"
   exit
fi

if $FFLAG; then
  if ! [[ -f $FILE_NM ]]; then
   echo "Invalid file name ${B}$FILE_NM${N}"
   exit
fi

fi

 
if ! $SFLAG; then 
   echo "Required parameter ${B}-s${N} missing"
   exit
fi




echo ""
echo "Sending requests for"
echo "____________________"
echo "${BG}Server:${N} $SERVER"
echo "${BG}App:${N} $APP_NM"
for FILE in "${FILE_NM[@]}"; do
    echo "${BG}File:${N} $FILE"
done
echo "${BG}Stores:${N} $STORES"
echo "${BG}Prereq:${N} $PREREQ"
echo "${BG}Expires:${N} $EXPIRES"
echo "${BG}Run After:${N} $AFTERDATE"
echo "${BG}Fix Option:${N} $FIXOPTION"
echo "${BG}Req to Fix:${N} $REQTOFIX"
echo ""

read -p "Are you sure? "
if ! [[ $REPLY =~ ^[Yy]$ ]]; then
  echo""
  exit 2
fi
echo ""
USER="--user SYSCTL:abc123 -k"

#if [ $SERVER != "https://smisdev.sherwin.com/polling" ]; then
#  read -s -p "Enter password for ${APP_NM}: " PASS
#  USER="--user ${APP_NM}:${PASS} -k"
#fi 

PARMS="{"

if [ ${PREREQ} ]; then
  if [ ${PARMS} != "{" ]; then
     PARMS="${PARMS},"
  fi
  PARMS="${PARMS}\"afterSequence\":\"${PREREQ}\"" 
fi

if [ ${EXPIRES} \] ; then
  if [ ${PARMS} != "{" ]; then
     PARMS="${PARMS},"
  fi
  PARMS="${PARMS}\"expiration\":\"${EXPIRES}\""
fi

if [ ${AFTERDATE} \] ; then
  if [ ${PARMS} != "{" ]; then
     PARMS="${PARMS},"
  fi
  PARMS="${PARMS}\"afterDate\":\"${AFTERDATE}\""
fi

if [ ${REQTOFIX} \] ; then
  if [ ${PARMS} != "{" ]; then
     PARMS="${PARMS},"
  fi
  PARMS="${PARMS}\"fixRequestId\":\"${REQTOFIX}\""
fi

if [ ${FIXOPTION} \] ; then
  if [ ${PARMS} != "{" ]; then
     PARMS="${PARMS},"
  fi
  PARMS="${PARMS}\"fixOption\":\"${FIXOPTION}\""
fi

PARMS="${PARMS}}"

STRING="${SERVER}/v1/app/${APP_NM}"
JSON=`curl $USER -X POST -H "Accept: application/json" $STRING`
REQID=`echo $JSON | cut -d\" -f4`
BASESTRING="${SERVER}/v1/${REQID}"
OPS="${BASESTRING}/operations"
STR="${BASESTRING}/stores"


echo ""
echo "Request $REQID generated"
echo $JASON

if [ ${PARMS} != "{}" ]; then 
 
    echo "Generating request header with parameters: ${PARMS}"
    RES=`curl $USER -X PUT -H "Accept: application/json" -H "Content-Type: application/json" -s -o /dev/null -w "%{http_code}" -d "${PARMS}" ${BASESTRING}`

    if [ ${RES} != 200 ]; then
        echo "Failed to generate request header. RC: ${RES}"
        exit
    fi
fi

echo ""
for FILE in "${FILE_NM[@]}"; do
  FN=`basename $FILE`
  MD5=`sha1sum $FILE | sed 's/ .*$//g'`
  echo $USER
  echo $FILE
  echo $FN
  echo $MD5
  echo $OPS
  echo "Adding operations to request: File: $FILE Checksum: $MD5"
  RES=`curl $USER -X POST -H "Accept: application/json" -s -o /dev/null -w "%{http_code}" -F "blob=@$FILE" -F "filename=$FN" -F "checksum=$MD5" -F "algorithm=SHA-1" -F "transforms=null" ${OPS}`

  if [ ${RES} != 201 ]; then
      echo "Failed to generate request operations. RC: ${RES}"
      exit
  fi
done
echo ""
if [ $STORES == "\"all\"" ]; then
	TYPE="chain"
else
	TYPE="store"
fi

echo
echo "Setting stores: $STORES"
RES=`curl $USER -X PUT -H "Accept: application/json" -H "Content-Type: application/json" -s -o /dev/null -w "%{http_code}" -d "{\"type\":\"$TYPE\",\"data\":[${STORES}]}" ${STR}`

if [ ${RES} != 201 ]; then
    echo "Failed to set stores. RC: ${RES}"
    exit
fi
echo ""
echo "Posting request to stores"
RES=`curl $USER -X POST -H "Accept: application/json" -s -o /dev/null -w "%{http_code}" "${BASESTRING}"`
if [ ${RES} == 206 ]; then
	echo "Stores posted, but not all successful"
	echo
fi

if [ ${RES} != 200 ]; then
    if [ ${RES} != 206 ]; then
	echo "Failed to post to store. RC: ${RES}"
    	exit
    fi
fi

echo ""
echo "${BG}Request ID:${N} $REQID submitted"
echo ""
