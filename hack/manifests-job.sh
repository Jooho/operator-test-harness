
#!/bin/bash
source ./env.sh


if [[ $1 == create ]]
then
cat <<EOF | oc apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: manifests-test-job
  namespace: ${TEST_NAMESPACE}
  labels:
    app:  manifests-test-job
    test: osd-e2e-test
spec:
  backoffLimit: 2
  completions: 1
  template:
    metadata:
      name: manifests-test-pod
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - $HOME/peak/installandtest.sh
        env:
        - name: JUPYTERHUB_NAMESPACE
          value: ${JUPYTERHUB_NAMESPACE}
        - name: PATH
          value: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        - name: TEST_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: ARTIFACT_DIR
          value: /tmp/artifacts 
        image: ${MANIFESTS_FULL_IMG_URL}
        name: manifests-test
        resources: {}
        volumeMounts:
        - mountPath: /tmp/artifacts
          name: artifacts
      volumes:
      - emptyDir: {}
        name: artifacts
      restartPolicy: Never
      serviceAccountName: ${MANIFESTS_NAME}-sa
EOF

else
  oc delete pod ${TEST_HARNESS_NAME}-pod --ignore-not-found
fi