Scylla_Cassandra_stress

A method to test and benchmark Scylla and Cassandra clusters

This repository will help you create a consistet and repeatable stress loads on a Scylla and Cassandra clusters.
The script creates write stress files and read stress files.
The write stress files are creating a range defined in te the number of transactions per loader. The number of loaders is determined from the ansible host file.
The write stress create a RF=3, default cassandra stress schema.
Each loader is assigned to his unuiqe range.

The script creates 2 read test,
The first, is targeted for large spread dataset, where the intention is to create a workload that is normally served from disk. Such workload can represent a case in which servers memory is smaller than the dataset used, or when the data queries are not cached in memory. We named this workload readlarge 
The second, is targeted for small spread dataset, where the intention is to create a workload that is normally served from memory. Such workload can represent a case in which servers memory holds all the  dataset used, or when the data queries are  cached in memory. We named this workload readsmall 


#### install
Make sure you installed the following:
* [ansible](http://docs.ansible.com/ansible/intro_installation.html)
* [python boto](https://github.com/boto/boto#installation)
* [perl](https://learn.perl.org/installing/)

```
Usage: generate_loadfiles.pl [outputfilenames prefix] [ansible host file] [loaders header ini file] [hosts' user name] [# of write transaction per loader] [C*/Scylla servers IPs]
```
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
After executing the script the user will be prompted with next step to execute the stress tests.
First we will transfer the stress files to the loaders servers, and make sure they are executable
```
Dear Benchmark creator!
 You have now created the loader files, the small and large read files.
 The next step is to copy them to your loaders. Make sure you have defined correctly ssh key
 And changed the user from centos to your user name in the loaders
 To send the files to the loaders, copy and past the following command to you command line shell
 source loadersfiles.sh
 using ansible ad-hoc command, change the files attributes to be exectuables
 ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a "sudo chmod 777 writetest.532017.sh"
 ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a "sudo chmod 777 readlarge.532017.sh"
 ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a "sudo chmod 777 readsmall.532017.sh"
 To execute the tests, use the ansible ad-hoc commands and wait for complition
 For example:
 ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a "./readsmall.532017.sh"
 To collect the information from the loaders use, again, the ansible ad-hoc command:
 ansible -i mymachines.ini loaders -u centos --private-key ~/.ssh/id_rsa -m shell -a "tail -16 testreadsmall_532017_retest_latency_rate_limit.data" > myresults.txt
 Use the script, getinfo.pl to extract the results in csv format, for example:
 ./getinfo.pl  myresults.txt
 row rate ,65759,63675,65272
 latency mean ,7.6,7.8,7.6
 latency median ,3.2,3.4,3.2
 latency 95th percentile ,5.7,6.0,5.7
 latency 99th percentile ,18.1,15.9,13.4
 latency 99.9th percentile ,386.9,387.0,385.8
 latency max ,896.1,921.7,851.8

```
