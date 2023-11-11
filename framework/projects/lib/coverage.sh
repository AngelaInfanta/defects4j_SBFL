#!/bin/bash

#TODO: make the included files only be that included by defects4j

defects4j compile
work_dir="$(pwd)"

export GZOLTAR_AGENT_JAR="$D4J_HOME/framework/projects/lib/gzoltar-agent-rt.jar"
export GZOLTAR_CLI_JAR="$D4J_HOME/framework/projects/lib/gzoltar-cli.jar"
export HAMCREST_JAR="$D4J_HOME/framework/projects/lib/hamcrest.jar"
export JUNIT_JAR="$D4J_HOME/framework/projects/lib/junit-4.11.jar"

test_classpath=$(defects4j export -p cp.test)
src_classes_dir=$(defects4j export -p dir.bin.classes)
src_classes_dir="$work_dir/$src_classes_dir/"
test_classes_dir=$(defects4j export -p dir.bin.tests)
test_classes_dir="$work_dir/$test_classes_dir"
src_code_dir=$(defects4j export -p dir.src.classes)
src_code_dir="$work_dir/$src_code_dir/"

unit_tests_file="$work_dir/unit_tests.txt"
relevant_tests=*

java -cp "$test_classpath:$test_classes_dir:$JUNIT_JAR:$GZOLTAR_CLI_JAR" \
  com.gzoltar.cli.Main listTestMethods \
    "$test_classes_dir" \
    --outputFile "$unit_tests_file" \
    --includes "$relevant_tests" > /dev/null

relevant="$(find $src_code_dir -print | grep .java | sed "s#$src_code_dir##g" | sed "s#/#.#g" | sed "s#.java##g" | paste -s -d ':')"

ser_file="$work_dir/gzoltar.ser"

excluded="$(sed -e 's/^.*\.\([^\.]*\)#.*/*\1*/' $unit_tests_file | sort | uniq | paste -sd ':')"
excluded="$excluded:*junit*"
#export _JAVA_OPTIONS="-Xmx6144M -XX:MaxHeapSize=4096M"
#-XX:MaxPermSize=4096M
java -javaagent:$GZOLTAR_AGENT_JAR=destfile=$ser_file,buildlocation=$src_classes_dir,excludes="$excluded" \
  -cp "$test_classpath:$JUNIT_JAR:$GZOLTAR_CLI_JAR" \
  com.gzoltar.cli.Main runTestMethods \
  --testMethods "$unit_tests_file" \
  --collectCoverage > /dev/null

echo "Done collecting coverage"

java -Xmx10g -cp "$test_classpath:$src_classes_dir:$JUNIT_JAR:$HAMCREST_JAR:$GZOLTAR_CLI_JAR" \
    com.gzoltar.cli.Main faultLocalizationReport \
      --buildLocation "$src_classes_dir" \
      --granularity "line" \
      --dataFile "$ser_file" \
      --family "sfl" \
      --formula "Barinel" \
      --outputDirectory "$work_dir" > /dev/null
      #--metric "entropy" \
      #--formatter "txt" \
      #--inclPublicMethods \
      #--inclStaticConstructors \
      #--inclDeprecatedMethods \
