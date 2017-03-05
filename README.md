Scylla_Cassandra_stress

A method to test and benchmark Scylla and Cassandra clusters

This repository will help you create a consistet and repeatable stress loads on a Scylla and Cassandra clusters.

#### install
Make sure you installed the following:
* [ansible](http://docs.ansible.com/ansible/intro_installation.html)
* [python boto](https://github.com/boto/boto#installation)
* [perl](https://learn.perl.org/installing/)

Usage: generate_loadfiles.pl [outputfilenames prefix] [ansible host file] [loaders header ini file] [hosts' user name] [# of write transaction per loader] [C*/Scylla servers IPs]
Example: 
```
generate_loadfiles.pl i2xlarge_scylla1.6 scyllatest.ini loaders centos 11600000 172.10.1.4,172.10.1.5,172.10.1.6
```
All fileds are mandatory. The script will generate all the executable files to complete Cassandra stress testing
To complete the execution of the tests you will use ansible in ad-hoc mode (command line)
Your ansible host file should have entries similar to the below example
```
[loaders]
54.3.2.1
54.3.2.2
54.3.2.3
[servers]
54.3.3.9
54.3.3.10
54.3.3.11
```

Once you deploy the script, it will create write files in your directory, the number of the write files is the same as the number of loaders you'll be using.
It advised to remove the temporary files, once you complete the uploading of the stress files.
To prevent prompting for confirmation about ssh authentications please type the following

```
export ANSIBLE_HOST_KEY_CHECKING=False
```

