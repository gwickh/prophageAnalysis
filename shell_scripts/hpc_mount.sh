#!/usr/bin/env bash

mkdir whitchurch-group;
sudo mount.cifs //smb.qib-hpc-data.ciscloud/Research-Projects/TraDIS_WhitchurchLab ~/whitchurch-group -o domain=nr4,user=wickhamg,uid=$(id -u),gid=$(id -g),mfsymlinks


