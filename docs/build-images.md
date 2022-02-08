# Build Base Images
There are 2 base images that are being used by operator test harness, manifests repositories for ISV.
These base images need be updated regularly but ISV is reponsible for the update. This document explains how to build the base images.

## ODS-CI Base Image
Red Hat is using Robot framework which is based on selenium and it is opensource. So if you want to verify ISV application by a sample notebook in the test harness, you can use this repository. This repository provide [a Dockerfile](https://github.com/red-hat-data-services/ods-ci/blob/master/build/Dockerfile) and also [the docker image](https://quay.io/repository/odsci/ods-ci?tag=latest&tab=tags).

By default, template manifests base Dockerfile use quay.io/jooholee/osd-ci:stable image but I recommend you to fork the original repository and build your own image with `stable` branch. Then use the new imge in the manifests base Dockerfile. However, you need to change 2~3 lines. Please refer this [Dockerfile](https://github.com/Jooho/ods-ci/blob/stable_isv/build/Dockerfile) that the default image built.

*Differences:* 
- [`HOME` directory to `/root`](https://github.com/Jooho/ods-ci/blob/stable_isv/build/Dockerfile#L7)
- [update pip3](https://github.com/Jooho/ods-ci/blob/stable_isv/build/Dockerfile#L22)
  
**Build steps for template ods-ci Base Image**
~~~
git clone --branch stable_isv  git@github.com:Jooho/ods-ci.git
cd stable_isv
podman build -t quay.io/jooholee/ods-ci:stable -f build/Dockerfile .
podman push quay.io/jooholee/ods-ci:stable
~~~

**Build steps for your own osd-ci Base Image**
First, you have to fork upstream ods-ci repo(https://github.com/red-hat-data-services/ods-ci)
~~~
git clone --branch stable  git@github.com:YOUR_NAME/ods-ci.git
git checkout -b stable_isv
~~~
Update Docker file (./build/Dockerfile)
~~~
podman build -t quay.io/YOUR_NAME/ods-ci:stable -f build/Dockerfile .
podman push quay.io/YOUR_NAME/ods-ci:stable
~~~

## Manifests Base Image
manifests-test use 2 images to separate sources and dependencies. For the dependencies, the base image is being used and this explain how to build the base image. It is also recommended to have your own base image.


**Build steps for template manifests Base Image**
~~~
git clone --branch template  git@github.com:Jooho/manifests-test.git 
cd manifests-test
make base-image
~~~

**Build steps for your own manifests Base Image**
`isv-cli test-harness create` command will provide XXXX-operater-manifests folder based on config.ini information.You can build the base image with Makefile under the folder.

~~~
cd XXXX-operator-manifests
make base-image
~~~
