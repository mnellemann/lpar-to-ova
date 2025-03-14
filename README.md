Make OVA 
===========

This script will help you generate a OVA file for import into IBM Cloud PowerVS Workspace.

*For more information, contact: Lars Johannesson "larsj AT dk.ibm.com"*


#### Dump LPAR disks

Dump all LUNs with the `dd` command and use *.img* for output file extension.

#### Download the script

```shell
curl -o make-ova.sh https://raw.githubusercontent.com/mnellemann/lpar-to-ova/refs/heads/main/make-ova.sh
chmod +x make-ova.sh
```


#### Run the script

First image file (from natural sort with *ls -v*) is assumed to be the *boot* disk, and the rest are data disks.

```shell
Usage: make-ova.sh [-a <ppc64|ppc64le>] [-o <ibmi|aix|linux>] [-n <name>]
```

IBMi example:

```shell
/path/to/make-ova.sh -a ppc64 -o ibmi -n IBMI-02
```


## TODO

- What are requirements for image name (eg. no white space)
