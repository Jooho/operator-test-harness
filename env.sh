# Customize
OPERATOR_NAME=odh-operator                   # Format %PRODUCT_NAME%-operator ex) odh-operator
OPERATOR_CRD_API=kfdefs.kfdef.apps.kubeflow.org
GIT_REPO_HOST=https://github.com
GIT_REPO_ORG=Jooho
GIT_REPO_BRANCH=master
IMG_REG_HOST=quay.io
IMG_REG_ORG=jooholee
TEST_NAMESPACE=${OPERATOR_NAME}
TEST_HARNESS_IMG_TAG=latest
MANIFESTS_IMG_TAG=latest

#---------------------------------------------
# Do NOT CHANGE
# TEST HARNESS
# TEST_HARNESS_NAME=operator-test-harness
TEST_HARNESS_NAME=${OPERATOR_NAME}-test-harness
TEST_HARNESS_IMG=${TEST_HARNESS_NAME}
TEST_HARNESS_GIT_REPO_URL=${GIT_REPO_HOST}/${GIT_REPO_ORG}/${TEST_HARNESS_NAME}
TEST_HARNESS_FULL_IMG_URL=${IMG_REG_HOST}/${IMG_REG_ORG}/${TEST_HARNESS_IMG}:${TEST_HARNESS_IMG_TAG}


# MANIFESTS
# MANIFESTS_NAME=manifests-test
MANIFESTS_NAME=${OPERATOR_NAME}-manifests-test
MANIFESTS_IMG=${MANIFESTS_NAME}
MANIFESTS_GIT_REPO_URL=${GIT_REPO_HOST}/${GIT_REPO_ORG}/${MANIFESTS_NAME}
MANIFESTS_FULL_IMG_URL=${IMG_REG_HOST}/${IMG_REG_ORG}/${MANIFESTS_IMG}:${MANIFESTS_IMG_TAG}
## Location inside the container where CI system will retrieve files after a test run
ARTIFACT_DIR=/tmp/artifacts
LOCAL_ARTIFACT_DIR="${PWD}/artifacts"

# ETC
OPERATOR_NAME_SHORT=$(echo ${a}|cut -d- -f1)