#!/bin/bash


# Valid architectures and OS types
archs=(ppc64 ppc64le)
types=(ibmi aix linux)


# Print usage information and exit
usage() { echo "Usage: $0 [-a <ppc64|ppc64le>] [-o <ibmi|aix|linux>] [-n <name>]" 1>&2; exit 1; }


###
### Power VC Meta
###

# Write PowerVC meta file
make_meta_file() {
  os=$1
  arch=$1

  echo "os-type = ${t}"
  echo "architecture = ${a}"

  type="boot"
  num=1

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
    echo "    <rasd:ResourceType>17</rasd:ResourceType>"
    echo "    <ns${num}:boot xmlns:ns${num}="ibmpvc">$boot</ns${num}:boot>"
    echo "  </ovf:Item>"
    num=$((num+1))
    boot="False"
  done

#      <ovf:Item>
#          <rasd:Description>Temporary clone for export</rasd:Description>
#          <rasd:ElementName>Image_P10_IBM05_volume_1</rasd:ElementName>
#          <rasd:HostResource>ovf:/disk/disk1</rasd:HostResource>
#          <rasd:InstanceID>1</rasd:InstanceID>
#          <rasd:ResourceType>17</rasd:ResourceType>
#          <ns1:boot xmlns:ns1="ibmpvc">True</ns1:boot>
#        </ovf:Item>
#        <ovf:Item>
#          <rasd:Description>Temporary clone for export</rasd:Description>
#          <rasd:ElementName>Image_P10_IBM05_volume_2</rasd:ElementName>
#          <rasd:HostResource>ovf:/disk/disk2</rasd:HostResource>
#          <rasd:InstanceID>2</rasd:InstanceID>
#          <rasd:ResourceType>17</rasd:ResourceType>
#          <ns2:boot xmlns:ns2="ibmpvc">False</ns2:boot>
#        </ovf:Item>
  echo "RESOURCES"
}


# Write OVF Manifest
make_ovf_file() {
  type=$1
  arch=$2
  name=$3

  # Build parts and search/replace in template file
  ref=$(make_ovf_references)
  dsk=$(make_ovf_disks)
  res=$(make_ovf_storage_resources)

  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  echo "<ovf:Envelope xmlns:ovf=\"http://schemas.dmtf.org/ovf/envelope/1\" xmlns:rasd=\"http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance\">"
  echo "  <ovf:References>"
  echo $ref
  echo "  </ovf:References>"
  echo "  <ovf:DiskSection>"
  echo $dsk
  echo "  </ovf:DiskSection>"
  echo "  <ovf:VirtualSystemCollection>"
  echo "    <ovf:VirtualSystem ovf:id=\"vs0\">"
  echo "      <ovf:Name>$name</ovf:Name>"
  echo "      <ovf:Info></ovf:Info>"
  echo "      <ovf:ProductSection>"
  echo "        <ovf:Info/>"
  echo "        <ovf:Product/>"
  echo "      </ovf:ProductSection>"
  echo "      <ovf:OperatingSystemSection ovf:id=\"11\">"
  echo "        <ovf:Info/>"
  echo "        <ovf:Description>$type</ovf:Description>"
  echo "        <ns0:architecture xmlns:ns0=\"ibmpvc\">$arch</ns0:architecture>"
  echo "      </ovf:OperatingSystemSection>"
  echo "      <ovf:VirtualHardwareSection>"
  echo $res
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
[[ "$n" =~ ^[a-z0-9]{3,}$ ]] || (echo " > Name not valid"; usage)

# Debug
#echo "name = ${n}"
#echo "arch = ${a}"
#echo "os = ${o}"


make_meta_file $o $a > "${n}.meta"
make_ovf_file  $o $a $n > "${n}.ovf"
