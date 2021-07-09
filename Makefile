# IMAGE_REGISTRY ?=$(DEFAULT_IMAGE_REGISTRY)
# REGISTRY_NAMESPACE ?=$(DEFAULT_REGISTRY_NAMESPACE)
# IMAGE_TAG ?=$(DEFAULT_IMAGE_TAG)
# TEST_HARNESS_FULL_IMAGE_NAME=$(IMAGE_REGISTRY)/$(REGISTRY_NAMESPACE)/$(TEST_HARNESS_NAME):$(IMAGE_TAG)

DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OUT_FILE := "$(DIR)$(TEST_HARNESS_NAME)"

include $(shell pwd)/env
build:
	CGO_ENABLED=0 go test -v -c

build-image:
	@echo "Building the $(TEST_HARNESS_NAME)"
	podman build --format docker -t $(TEST_HARNESS_FULL_IMAGE_NAME) -f $(shell pwd)/Dockerfile .

push-image:
	@echo "Pushing the $(TEST_HARNESS_NAME) image to $(IMAGE_REGISTRY)/$(REGISTRY_NAMESPACE)"
	podman push $(TEST_HARNESS_FULL_IMAGE_NAME)

image: build-image push-image

# This script create a SA which has cluster-admin role. This is needed to mimik OSD E2E test environment.
test-setup:
	./hack/setup.sh

# test-X are for test purpose of OPERATOR-TEST-HARNESS
# It deploys NFS provisioner operator as a test operator
test-operator:
	oc create -f ./hack/nfsprovisioner-operator/cs.yaml 
	./hack/nfsprovisioner-operator/og.sh create
	oc create -f ./hack/nfsprovisioner-operator/subs.yaml -n $(TEST_NAMESPACE) 
	oc create -f ./hack/nfsprovisioner-operator/cr.yaml -n $(TEST_NAMESPACE) 

# It removes running NFS provisioner operator
test-operator-clean:
	oc delete -f ./hack/nfsprovisioner-operator/cr.yaml -n $(TEST_NAMESPACE)  --ignore-not-found
	oc delete -f ./hack/nfsprovisioner-operator/subs.yaml -n $(TEST_NAMESPACE)  --ignore-not-found
	./hack/nfsprovisioner-operator/og.sh delete 
	oc delete -f ./hack/nfsprovisioner-operator/cs.yaml  --ignore-not-found
	oc delete deploy nfs-provisioner-operator-controller-manager -n $(TEST_NAMESPACE) --ignore-not-found
	

job-test:
	oc delete job $(MANIFESTS_TEST)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc get sa $(MANIFESTS_TEST)-sa -n $(TEST_NAMESPACE) || $(MAKE) test-setup
	oc create -f ./template/manifests-test-job.yaml -n $(TEST_NAMESPACE) 

job-test-clean:
	oc delete sa $(MANIFESTS_TEST)-sa -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete rolebinding $(MANIFESTS_TEST)-rb -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete job manifests-test-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_TEST)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod jupyterhub-nb-admin -n redhat-ods-applications  --ignore-not-found --force --grace-period=0
	oc delete pvc jupyterhub-nb-admin-pvc -n redhat-ods-applications  --ignore-not-found

cluster-test:
	oc delete pod $(TEST_HARNESS_NAME)-pod -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete job manifests-test-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_TEST)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc get sa $(MANIFESTS_TEST)-sa -n $(TEST_NAMESPACE) || $(MAKE) test-setup
	./hack/operator-test-harness-pod.sh create

	# oc run $(TEST_HARNESS_NAME)-pod --image=$(TEST_HARNESS_FULL_IMAGE_NAME) --restart=Never --attach -i --tty --serviceaccount $(TEST_HARNESS_NAME)-sa -n $(TEST_NAMESPACE) --env=JOB_PATH=/home/prow-manifest-test-job-pvc.yaml
	# oc logs prow-operator-test-harness-pod -c prow -f

cluster-test-clean:
	./hack/operator-test-harness-pod.sh delete
	oc delete sa $(MANIFESTS_TEST)-sa -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete rolebinding $(MANIFESTS_TEST)-rb -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete job manifests-test-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_TEST)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod jupyterhub-nb-admin  -n redhat-ods-applications --ignore-not-found --force --grace-period=0
	oc delete pvc jupyterhub-nb-admin-pvc -n redhat-ods-applications  --ignore-not-found
