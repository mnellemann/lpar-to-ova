#!/bin/bash

# Work by:
# Lars Johannesson <larsj@dk.ibm.com>
# Mark Nellemann <mark.nellemann@ibm.com>


# Valid architectures and OS types
archs=(ppc64 ppc64le)
types=(ibmi aix rhel sles ubuntu coreos)


# Print usage information and exit
usage() { echo "Usage: $0 [-a <ppc64|ppc64le>] [-o <ibmi|aix|linux>] [-n <name>]" 1>&2; exit 1; }



###
### Power VC Meta
###

# Write PowerVC meta file
make_meta_file() {
  os=$1
  arch=$1

  type="boot"
  num=1

  # The 'os-type' must be one of ['aix', 'ibmi', 'rhel', 'sles', 'ubuntu', 'coreos']
  echo "os-type = ${os}"
  echo "architecture = ${arch}"
  for img in `ls -v *.img`; do
    echo "vol${num}-file = $img"
    echo "vol${num}-type = $type"
    type="data"
    num=$((num+1))
  done
}



###
### OVF Manifest
###

make_ovf_references() {
  num=1
  for img in `ls -v *.img`; do
    size=$(du -sb $img | cut -f 1)
    echo "<ovf:File href=\"${img}\" id=\"file${num}\" size=\"${size}\"/>"
    num=$((num+1))
  done
}


make_ovf_disks() {
  echo "<ovf:Info>Disk Section</ovf:Info>"
  num=1
  for img in `ls -v *.img`; do
    size=$(du -sb $img | cut -f 1)
    echo "<ovf:Disk capacity=\"${size}\" capacityAllocationUnits=\"byte\" diskId=\"disk${num}\" fileRef=\"file${num}\"/>"
    num=$((num+1))
  done
}


make_ovf_storage_resources() {
  echo "<ovf:Info>Storage resources</ovf:Info>"

  boot="True"
  num=1
  for img in `ls -v *.img`; do
    echo "  <ovf:Item>"
    echo "    <rasd:Description>Temporary clone for export</rasd:Description>"
    echo "    <rasd:ElementName>${img}</rasd:ElementName>"
    echo "    <rasd:HostResource>ovf:/disk/disk${num}</rasd:HostResource>"
    echo "    <rasd:InstanceID>${num}</rasd:InstanceID>"
    echo "    <rasd:ResourceType>17</rasd:ResourceType> <!-- FIXME: What is valid here? -->"
    echo "    <ns${num}:boot xmlns:ns${num}=\"ibmpvc\">$boot</ns${num}:boot>"
    echo "  </ovf:Item>"
    num=$((num+1))
    boot="False"
  done
}


# Write OVF Manifest
make_ovf_file() {
  type=$1 # OS
  arch=$2
  name=$3

  # Build parts and search/replace in template file
  ref=$(make_ovf_references)
  dsk=$(make_ovf_disks)
  res=$(make_ovf_storage_resources)

  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo "<ovf:Envelope xmlns:ovf=\"http://schemas.dmtf.org/ovf/envelope/1\" xmlns:rasd=\"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance\">"
  echo "  <ovf:References>"
  echo "$ref"
  echo "  </ovf:References>"
  echo "  <ovf:DiskSection>"
  echo "$dsk"
  echo "  </ovf:DiskSection>"
  echo "  <ovf:VirtualSystemCollection>"
  echo "    <ovf:VirtualSystem ovf:id=\"vs0\">"
  echo "      <ovf:Name>$name</ovf:Name>"
  echo "      <ovf:Info></ovf:Info>"
  echo "      <ovf:ProductSection>"
  echo "        <ovf:Info/>"
  echo "        <ovf:Product/>"
  echo "      </ovf:ProductSection>"
  echo "      <ovf:OperatingSystemSection ovf:id=\"11\"> <!-- FIXME: What is valid here? -->"
  echo "        <ovf:Info/>"
  echo "        <ovf:Description>$type</ovf:Description> <!-- FIXME: What is valid here? -->"
  echo "        <ns0:architecture xmlns:ns0=\"ibmpvc\">$arch</ns0:architecture>"
  echo "      </ovf:OperatingSystemSection>"
  echo "      <ovf:VirtualHardwareSection>"
  echo "$res"
  echo "      </ovf:VirtualHardwareSection>"
  echo "    </ovf:VirtualSystem>"
  echo "    <ovf:Info/>"
  echo "    <ovf:Name>$name</ovf:Name>"
  echo "  </ovf:VirtualSystemCollection>"
  echo "</ovf:Envelope>"

}



###
### Main
###

# Parse command line options
while getopts ":a:o:n:h" opt; do
  case "${opt}" in
    a)
      a=${OPTARG}
      [[ $(echo ${archs[@]} | fgrep -w "$a") ]] || usage
      ;;
    o)
      o=${OPTARG}
      [[ $(echo ${types[@]} | fgrep -w "$o") ]] || usage
      ;;
    n)
      n=${OPTARG}
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))


# In case of missing options, print usage
if [ -z "${a}" ] || [ -z "${o}" ] || [ -z "${n}" ]; then
  echo " > Missing or invalid options"
  usage
fi


# Validate name input
if [[ ! "$n" =~ ^[A-Za-z0-9._-]{3,32}$ ]]; then
  echo " > Name not valid"
  exit 1
fi


# Check that we have *.img files
ls *.img >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo " > No .img files found"
  exit 1
fi


# Present disk images
echo
echo "We will be using the following image files in the order shown:"
echo -n " > "; ls -v *.img
echo
echo "Press CTRL-C to abort or ENTER to continue."
read



# Debug
#echo "name = ${n}"
#echo "arch = ${a}"
#echo "os = ${o}"

make_meta_file $o $a > "${n}.meta"
make_ovf_file  $o $a $n > "${n}.ovf"

echo
echo "Create the OVA file:"
echo "  tar zcvf /mnt/bigdisk/${name}.ova.gz ${name}.meta ${name}.ovf *.img"
echo

echo
echo "TODO: Upload ova file to COS with the s3cmd"
echo
