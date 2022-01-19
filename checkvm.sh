cat check.sh 
#!/bin/bash

virsh destroy $1 &&

rbd feature enable $1 object-map
rbd feature enable $1 fast-diff
rbd feature enable $1 deep-flatten

rbd feature disable $1 object-map
rbd feature disable $1 fast-diff
rbd feature disable $1 deep-flatten

rbd feature enable $1 object-map
rbd feature enable $1 fast-diff
rbd feature enable $1 deep-flatten

virsh start $1
