. /home/env.sh
echo "Create a PVC for storing ods-ci artifacts"
oc create -f /home/artifacts-pvc.yaml

echo "Testing Operator by test harness"
JUPYTER_NOTEBOOK_PATH=${JUPYTER_NOTEBOOK_PATH} /operator-test-harness.test

echo "Waiting for manifests test"
oc wait --for=condition=complete job/manifests-test-job

echo "Trasfering the artifacts dump to Test Harness Pod"
oc create -f /home/download-artifacts-pod.yaml
oc rsync download-artifacts-pod:${ARTIFACT_DIR} /test-run-results/
