#!/bin/bash
tee -a /etc/security/limits.conf << EOF
*               soft nofile 102400
*               soft nofile 102400
EOF

