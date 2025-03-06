Make OVA 
===========

Export all LUNs with the `dd` command and use *.img* for output file extension.

First image file (natural sort *ls -v*) is assumed to be the *boot* disk, and the rest are data disks.

Run the `make-ova.sh` script.

```shell
Usage: ./make-ova.sh [-a <ppc64|ppc64le>] [-o <ibmi|aix|linux>] [-n <name>]
```



## TODO

- What are requirements for image name (eg. no white space)
