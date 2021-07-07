
#!/bin/bash
source ./env.sh


if [[ $1 == create ]]
then
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${TEST_HARNESS_NAME}-pod
  namespace: ${TEST_NAMESPACE}
  labels:
    app: ${TEST_HARNESS_NAME}
spec:
  restartPolicy: Never
  containers:
  - name: test-results
    command:
    - /bin/bash
    - -c
    - 'trap : TERM INT; sleep infinity & wait'
    image: docker.io/openshift/origin-cli
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - mountPath: /test-run-results 
      name: test-run-results
  - name: operator
    image: ${TEST_HARNESS_FULL_IMAGE_NAME}
    imagePullPolicy: Always
    volumeMounts:
    - mountPath: /test-run-results 
      name: test-run-results
  serviceAccount: ${TEST_HARNESS_NAME}-sa
  serviceAccountName: ${TEST_HARNESS_NAME}-sa
  volumes:
  - name: test-run-results
    emptyDir: {}
EOF

else
  oc delete pod ${TEST_HARNESS_NAME}-pod
fi