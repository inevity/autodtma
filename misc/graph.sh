#!/bin/bash
./FileCollector.sh testname www.myweb.com

if [ $Sessionbased -eq 1 ]; then
./GraphGenerator.sh $testname $TotalCores $ActiveCoreLocation jpeg 200 $connections ./
else
./GraphGenerator.sh testname $TotalCores 2 jpeg $Sessionbased $connections ./
fi
