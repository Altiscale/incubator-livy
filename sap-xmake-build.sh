#!/bin/bash -l

# This build script is only applicable to Spark without Hadoop and Hive

PACKAGE_BRANCH="sap-branch-0.6.1-alti"
HADOOP_VERSION="2.7.4"
SPARK_VERSION="2.3.2"
SCALA_VERSION="2.11"
LIVY_VERSION="0.6.1"

export M2_HOME=/opt/mvn3
export JAVA_HOME=/opt/java
export PATH=$M2_HOME/bin:$JAVA_HOME/bin:$PATH

# The base image has both python2 and python3 installed and the symlink /usr/bin/python is pointing to python2 by default.
# We are setting the alias for python pointing to python3 instead of manipulating the symlink.
alias python=python3

curr_dir=`dirname $0`
curr_dir=`cd $curr_dir; pwd`
git_hash=""

env | sort

if [ "x${PACKAGE_BRANCH}" = "x" ] ; then
  echo "error - PACKAGE_BRANCH is not defined. Please specify the branch explicitly. Exiting!"
  exit -9
fi

echo "ok - extracting git commit label from user defined $PACKAGE_BRANCH"

git_hash=$(git rev-parse HEAD | tr -d '\n')
echo "ok - we are compiling livy branch $PACKAGE_BRANCH upto commit label $git_hash"

echo "build - entire livy project in $curr_dir"

if [ "x${HADOOP_VERSION}" = "x" ] ; then
  echo "fatal - HADOOP_VERSION needs to be set, can't build anything, exiting"
  exit -8
fi

echo "ok - building entire pkg with HADOOP_VERSION=$HADOOP_VERSION SPARK_VERSION=$SPARK_VERSION scala=$SCALA_VERSION"


# PURGE LOCAL CACHE for clean build
# mvn dependency:purge-local-repository

########################
# BUILD ENTIRE PACKAGE #
########################
# Default JDK version applied is 1.8 here.

spark_profile_str=""
if [[ $SPARK_VERSION == 1.* ]] ; then
  spark_profile_str="-Pspark-1.6"
elif [[ $SPARK_VERSION == 2.1.* ]] ; then
  spark_profile_str="-Pspark-2.1"
elif [[ $SPARK_VERSION == 2.2.* ]] ; then
  spark_profile_str="-Pspark-2.2"
elif [[ $SPARK_VERSION == 2.3.* ]] ; then
  spark_profile_str="-Pspark-2.3"
else
  echo "fatal - Unrecognize spark version $SPARK_VERSION, can't continue, exiting, no cleanup"
  exit -9
fi

mvn_cmd="mvn -U -X $spark_profile_str package -DskipTests"
echo "$mvn_cmd"
$mvn_cmd

if [ $? -ne "0" ] ; then
  echo "fail - Livy $LIVY_VERSION build failed!"
  exit -99
fi

########################
# BUILD RPM            #
########################

DATE_STRING=`date +%Y%m%d%H%M%S`
GIT_REPO="https://github.com/Altiscale/incubator-livy"

INSTALL_DIR="${curr_dir}/livy_rpmbuild"
mkdir --mode=0755 -p ${INSTALL_DIR}

export RPM_NAME="alti-livy-${LIVY_VERSION}"
export RPM_DESCRIPTION="Apache Livy ${LIVY_VERSION}\n\n${DESCRIPTION}"
export RPM_DIR="${INSTALL_DIR}/rpm/"
mkdir -p --mode 0755 ${RPM_DIR}

echo "Packaging livy rpm with name ${RPM_NAME} with version ${LIVY_VERSION}-${DATE_STRING}"

export RPM_BUILD_DIR="${INSTALL_DIR}/opt/alti-livy-${LIVY_VERSION}"
mkdir --mode=0755 -p ${RPM_BUILD_DIR}
mkdir --mode=0755 -p ${INSTALL_DIR}/etc/livy
cd ${RPM_BUILD_DIR}
mkdir --mode=0755 lib

mv ${curr_dir}/assembly/target/apache-livy-${LIVY_VERSION}-incubating-SNAPSHOT-bin.zip ${INSTALL_DIR}/opt/
pushd ${INSTALL_DIR}/opt/
unzip apache-livy-${LIVY_VERSION}-incubating-SNAPSHOT-bin.zip 
mv apache-livy-${LIVY_VERSION}-incubating-SNAPSHOT-bin ${RPM_BUILD_DIR}
popd

cd ${RPM_DIR}

fpm --verbose \
--maintainer ops@verticloud.com \
--vendor Altiscale \
--provides ${RPM_NAME} \
--description "${DESCRIPTION}" \
--url "${GITREPO}" \
--license "Apache License v2" \
--epoch 1 \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${LIVY_VERSION} \
--iteration ${DATE_STRING} \
--rpm-attr 755,root,root:/opt/livy/bin/livy-server \
-C ${INSTALL_DIR} \
opt etc

mv "${RPM_DIR}${RPM_NAME}-${LIVY_VERSION}-${DATE_STRING}.x86_64.rpm" "${RPM_DIR}/alti-livy-${LIVY_VERSION}.rpm"

echo "ok - build Livy $LIVY_VERSION and RPM completed successfully!"

exit 0
