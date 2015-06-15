#!/bin/bash
ansible-playbook --verbose -vvvv -f 1 build.yml
cd /usr/share/nginx/html/ 
dd if=/dev/zero of=612B bs=1 count=612
dd if=/dev/zero of=1KB bs=1024 count=1
dd if=/dev/zero of=32KB bs=1024 count=32
dd if=/dev/zero of=64KB bs=1024 count=64
dd if=/dev/zero of=96KB bs=1024 count=96
dd if=/dev/zero of=128KB bs=1024 count=128
dd if=/dev/zero of=192KB bs=1024 count=192
dd if=/dev/zero of=256KB bs=1024 count=256
dd if=/dev/zero of=320KB bs=1024 count=320
dd if=/dev/zero of=384KB bs=1024 count=384
dd if=/dev/zero of=448KB bs=1024 count=448
dd if=/dev/zero of=512KB bs=1024 count=512
dd if=/dev/zero of=576KB bs=1024 count=576
dd if=/dev/zero of=640KB bs=1024 count=640
dd if=/dev/zero of=768KB bs=1024 count=768
dd if=/dev/zero of=1MB bs=1024 count=1024
dd if=/dev/zero of=10MB bs=1024 count=10240
dd if=/dev/zero of=100MB bs=1024 count=102400
