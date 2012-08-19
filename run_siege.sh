#!/bin/bash
# Run Siege for 10 minutes with a single request pointed at the ELB configured
# for AutoScaling at AWS.

# Configure how many 64byte blocks to write using DD. I've found the sweet spot
# to be about 25000 in this proof of concept. t1.micros are tricky though
# because not all are created equally. If this number is too high then the
# t1.micro will spin out of control. If this number is too low, then
# autoscaling won't kick in.
COUNT=25000

CMD=`which siege`
if [ "$?" == "1" ]; then
  echo "siege is not installed or not in your current path."
  echo "sudo apt-get install siege"
  exit 1
fi

echo "Running AutoScaling Proof of Concept"
$CMD -c1 -t10M nodeload.catsatemybacon.net/?count=$COUNT
