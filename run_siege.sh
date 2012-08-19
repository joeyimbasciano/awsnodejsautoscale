#!/bin/bash
# Run Siege for 10 minutes with a single request pointed at the ELB configured
# for AutoScaling at AWS.
CMD=`which siege`
if [ "$?" == "1" ]; then
  echo "siege is not installed or not in your current path."
  echo "sudo apt-get install siege"
  exit 1
fi

echo "Running AutoScaling Proof of Concept"
$CMD -c1 -t10M nodeload.catsatemybacon.net/?count=50000
