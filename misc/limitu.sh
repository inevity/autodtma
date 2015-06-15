#!/bin/bash
tee -a /etc/security/limits.conf << EOF
*               soft nofile 344800
*               soft nofile 344800
EOF

