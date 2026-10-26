#!/bin/bash
# Check if VPN is connected
if ip link show | grep -q "tun0\|wg0"; then
    echo "VPN"
else
    echo ""
fi
