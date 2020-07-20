#!/usr/bin/env bash

# Copyright (C) 2020 Seagate, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions
# of the GNU General Public License v.2.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA


SKIP_WITH_LVMPOLLD=1

. lib/inittest

[ -z "$LVM_TEST_LOCK_TYPE_IDM" ] && skip;
[ -z "$LVM_TEST_FAILURE_INJECTION" ] && skip;

. lib/idm_setup
. lib/idm_cleanup

DISK1="$(basename -- ${BLK1%?})"
DISK2="$(basename -- ${BLK2%?})"
DISK3="$(basename -- ${BLK3%?})"

vgcreate --shared --locktype idm TESTVG1 $BLK1 $BLK2 $BLK3

# Create new logic volume
lvcreate -a ey --zero n -l 50%FREE -n foo1 TESTVG1

# Emulate fabric failure
echo 1 > /sys/block/$DISK1/device/delete
echo 1 > /sys/block/$DISK2/device/delete
echo 1 > /sys/block/$DISK3/device/delete

# Wait for 30s and will not lead to timeout
sleep 30

# Rescan drives so can access sdk again
echo "- - -" > /sys/class/scsi_host/host0/scan

# Wait for 40s and lock manager should can renew successfully
sleep 40

not check grep_lvmlockd_dump "S lvm_TESTVG1 kill_vg"

lvcreate -a n --zero n -l 10 -n foo2 TESTVG1

vgremove -f TESTVG1
