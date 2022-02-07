#!/bin/bash
source ./env.sh

oc project opendatahub

if [[ $1 == create ]]
then
echo "Create OperatorGroup"
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: kfdefs.kfdef.apps.kubeflow.org 
  name: opendatahub-operator
spec:
  targetNamespaces:
  - opendatahub
EOF
  
else
  oc delete OperatorGroup opendatahub-operator --ignore-not-found
fi



