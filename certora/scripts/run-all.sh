#CMN="--compilation_steps_only"
#CMN="--server staging"


echo
echo "1: aggregator.conf"
certoraRun $CMN  certora/confs/aggregator.conf\
            --msg "1. aggregator.conf"

echo
echo "2: executorV2.conf"
certoraRun $CMN  certora/confs/executorV2.conf \
            --msg "2. executorV2.conf"

echo
echo "3: executorV3.conf"
certoraRun $CMN  certora/confs/executorV3.conf \
            --msg "3. executorV3.conf"

