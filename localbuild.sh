#!/bin/bash

xmake -cie --debug-xmake --buildruntime linuxx86_64 \
      -I DOCKER=docker.wdf.sap.corp:50002 -I Common=http://nexus.wdf.sap.corp:8081/nexus/content/groups/build.milestones/ 
