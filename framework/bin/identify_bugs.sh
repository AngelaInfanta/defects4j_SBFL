#!/bin/bash
# This script assumes that `defects4j coverage` has already been run
coverage="sfl/txt"
help_message="USAGE: identify [-p <project> -b \"<bug> ...\" OR -v <version>] [-c <coverage dir>]"
while getopts ":c:b:p:v:hq" flag ;do
  case ${flag} in
    c) coverage=${OPTARG};;
    b)
      bugs=${OPTARG}
      bugs=$(echo $bugs | tr " " "\n" | sort -g | xargs)
    ;;
    p) project=${OPTARG};;
    v)
      version=${OPTARG}
      project="${version%%-*}"
      bugs="${version#*-}"
      bugs=$(echo $bugs | tr "-" "\n" | sort -g | xargs)
    ;;
    h) echo "$help_message";exit 0;;
    q) quiet=1;;
    \?)
      echo "Unsupported option: -$OPTARG" 1>&2
      exit 1
      ;;
    :) echo "Invalid option: $OPTARG requires an argument" 1>&2;;
  esac
done
shift $((OPTIND -1))
if [ -z "$bugs" ]; then
  echo "ERROR: no bugs given"
  echo "$help_message"
  exit 1
fi
if [ -z "$project" ]; then
  echo "ERROR: project not given"
  echo "$help_message"
  exit 1
fi
if [ ! -d "$coverage" ]; then
  echo "ERROR: could not find collected coverage, aborting..."
  exit 1
fi

version="${bugs##* }"
for bug in ${bugs[@]}; do
  #echo "fault: $bug"
  #output=$(./appPatch.sh $project $bug "/tmp/cloning/$version")
  output=$(python3 $D4J_HOME/framework/bin/backtrack.py $project $bug $version)
  # catch if "Bug not found" occurs:
  if [[ "$output" =~ ^Bug ]]; then
    if [ -z $quiet ]; then
      echo "Could not inject fault $bug in $project-${bugs// /-}: ${output#Bug not found: }"
    else
      echo "$bug"
    fi
  else
    #j=1
    found=0
    IFS=$'\n'
    for srcfile in $output; do
      IFS=','
      read -ra lines <<< "$srcfile"
        unset IFS
        #echo "$line"
        #fullpath=${lines[0]#$2/}
        fullpath=$(echo "${lines[0]}" | sed 's/.*org/org/')
        #fullpath=$(echo "${args[0]}" | sed "s#/tmp/$version/$2/##")
        fullpath=${fullpath%".java"}
        path=${fullpath%/*}
        file=${fullpath#"$path/"}
        path=${path//\//\.}
        #echo "file: $file"
        #echo "path: $path"
        #i=1
        for line in ${lines[@]:1}; do
          gr=$(grep "$path\$$file#.*:$line" $coverage/spectra.csv)
          #Below is the method to get close lines by grepping (not needed)
          #orig=$line
          #while [ -z "$gr" ] && [ $(expr $orig - $line) -lt 5 ]; do
            #line="$(expr $line - 1)"
            #gr=$(grep "$path\$$file#.*:$line" /root/fault_data/$project/$full/spectra.csv)
          #done
          #if [ $orig != $line ]; then
            #echo "$version: Bug $bug searched for on lines $line-$orig"
          #fi
          if [ ! -z "$gr" ]; then
            sed -i "/$path\$$file#.*:$line/s/$/:$bug/" $coverage/spectra.csv
            #echo "Injected fault $bug.$j.$i"
            found=1
          #else
            #echo "Could not inject fault $bug.$j.$i: not found in spectra"
          fi
          #i=$(expr $i + 1)
        done
        #j=$(expr $j + 1)
      done
      unset IFS
      if [ $found == 0 ]; then
        if [ -z $quiet ]; then
          echo "Bug $bug not materialized in spectrum of $project-${bugs// /-}"
        else
          echo "$bug"
        fi
      fi
  fi
done
