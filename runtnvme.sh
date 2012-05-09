#!/bin/bash

# Copyright (c) 2011, Intel Corporation.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

starttime="$(date +%s)"
TNVME_CMD_LINE=$@
BASE_OUT_DIR=./Logs
RUNNING_TEST=false

Usage() {
echo "usage...."
echo "  $0 <tnvme cmd line options>"
echo ""
}

if [ -z "$TNVME_CMD_LINE" ]; then
  Usage
  exit -1
fi

if [[ "$TNVME_CMD_LINE" == *-t* ]]; then
    RUNNING_TEST=true
fi

# Create a root logging directory. Sub-directories will be created by tnvme
# to house the dumping of various resources during test execution. A utility,
# svlogd, is used to create rotating logs from tnvme's stdout/stderr.
# You will most likley have to install svlogd to take advatage of the huge
# time savings introduced by this new logging/archiving scheme. The
# instructions dictating svlogd's behavior contained in ./${BASE_OUT_DIR}/config
rm -rf ${BASE_OUT_DIR}
mkdir -m 0777 ${BASE_OUT_DIR}
echo "s1000000" >${BASE_OUT_DIR}/config
echo "n3" >>${BASE_OUT_DIR}/config

# ./Logs/GrpInformative contains the resource dumps of GrpInformative
# ./Logs/GrpPending contains the resource dumps of the last group which executed
# ./Logs/current is the current output from tnvme via stderr/stdout
# ./Logs/*.s files are the result of svlogd rotating ./${BASE_OUT_DIR}/current
if [ $RUNNING_TEST == true ]; then
    # Pipe tnvme into the logging utility for 8 fold speed increase
    ../tnvme/tnvme --dump=${BASE_OUT_DIR} -k skiptest.cfg --golden=./identify.gold.xml $TNVME_CMD_LINE 2>&1 | svlogd -v -tt -b 2048 -l 0 ${BASE_OUT_DIR}
    ret=${PIPESTATUS[0]}
else
    # Allow tnvme to be slow, because we want to see the output immediately
    ../tnvme/tnvme --dump=${BASE_OUT_DIR} $TNVME_CMD_LINE 2>&1 
    ret=${PIPESTATUS[0]}
fi

# Cleanup files used to rotate logs, they are just noise
rm -f ${BASE_OUT_DIR}/lock
rm -f ${BASE_OUT_DIR}/config

# Report the end of the current log file
if [[ $ret -ne 0 ]]; then
    tail --lines=50 ${BASE_OUT_DIR}/current | grep -C 4 "Iteration SUMMARY"
else
    tail --lines=50 ${BASE_OUT_DIR}/current | grep -A 4 "Iteration SUMMARY"
fi

stoptime="$(date +%s)"
delta="$(expr $stoptime - $starttime)"
completed="Completed at `date`"
remainder="$(expr $delta % 3600)"
hours="$(expr $(expr $delta - $remainder) / 3600)"
seconds="$(expr $remainder % 60)"
minutes="$(expr $(expr $remainder - $seconds) / 60)"
elapsed="Elapsed runtime (hh:mm:ss): $hours:$minutes:$seconds"
echo $completed
echo $elapsed
echo $completed >> ${BASE_OUT_DIR}/current
echo $elapsed >> ${BASE_OUT_DIR}/current
exit $ret
