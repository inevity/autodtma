#!/bin/bash
cd /root/RUNs/httperf0.9.0-Patched-MultiplePorts
./configure
make
make install
cd /root/RUNs
g++ AverageCalculator.cpp -o average1
cd ~
