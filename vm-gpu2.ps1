# change ubuntu to your current vm name
$vm = "archlinux"

# this will remove any current gpu-p adapter then reattach them all
Remove-VMGpuPartitionAdapter -VMName $vm
Set-VM -VMName $vm -GuestControlledCacheTypes $true -LowMemoryMappedIoSpace 1GB -HighMemoryMappedIoSpace 32GB
Add-VMGpuPartitionAdapter -VMName $vm
echo "done"