DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OUT_FILE := "$(DIR)$(TEST_HARNESS_NAME)"

include $(shell pwd)/env
build:
	CGO_ENABLED=0 go test -v -c

build-image:
	@echo "Building the $(TEST_HARNESS_NAME)"
	podman build --format docker -t $(TEST_HARNESS_FULL_IMG_URL) -f $(shell pwd)/Dockerfile .

push-image:
	@echo "Pushing the $(TEST_HARNESS_NAME) image to $(IMG_REG_HOST)/$(IMG_REG_ORG)"
	podman push $(TEST_HARNESS_FULL_IMG_URL)

image: build-image push-image

# This script create a SA which has cluster-admin role. This is needed to mimik OSD E2E test environment.
test-setup:
	./hack/setup.sh

# If your cluster does not have RHODS ADDON, you can test your test-harness with ODH.
# This will deploy ODH in opendatahub namespace 
odh-deploy:
	oc project opendatahub || oc new-project opendatahub
	./hack/opendatahub/og.sh create
	oc create -f ./hack/odh-operator/subs.yaml -n opendatahub
	oc create -f ./hack/odh-operator/cr.yaml -n opendatahub

# This will delete ODH objects	
odh-deploy-clean:
	oc project opendatahub
	./hack/opendatahub/og.sh delete
	oc delete -f ./hack/odh-operator/cr.yaml -n opendatahub --force --grace-period=0 --wait
	oc delete -f ./hack/odh-operator/subs.yaml -n opendatahub --wait

# It deploys custom ISV operator using custom index.
# It gives you more flexible test environment and you can even test un-published new operator version.
isv-operator:
	ls ./hack/$(OPERATOR_NAME)/cs.yaml && oc create -f ./hack/$(OPERATOR_NAME)/cs.yaml 
	./hack/$(OPERATOR_NAME)/og.sh create
	oc create -f ./hack/$(OPERATOR_NAME)/subs.yaml -n $(TEST_NAMESPACE) 
	oc create -f ./hack/$(OPERATOR_NAME)/cr.yaml -n $(TEST_NAMESPACE) 

# It removes ISV operator with oc commands.
isv-operator-clean:
	oc delete -f ./hack/$(OPERATOR_NAME)/cr.yaml -n $(TEST_NAMESPACE)  --ignore-not-found
	oc delete -f ./hack/$(OPERATOR_NAME)/subs.yaml -n $(TEST_NAMESPACE)  --ignore-not-found
	./hack/$(OPERATOR_NAME)/og.sh delete 
	ls ./hack/$(OPERATOR_NAME)/cs.yaml && oc delete -f ./hack/$(OPERATOR_NAME)/cs.yaml  --ignore-not-found
	
# Test harness image will create a job object to deploy manifest but you can test only the job object. Before you test the test harness image on the cluster, this job must work.
job-test:
	oc delete job $(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc get sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) || $(MAKE) test-setup
	oc create -f ./template/manifests-test-job.yaml -n $(TEST_NAMESPACE) 

job-test-clean:
	oc delete sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete rolebinding $(MANIFESTS_NAME)-rb -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete job manifests-test-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod jupyterhub-nb-admin -n redhat-ods-applications  --ignore-not-found --force --grace-period=0
	oc delete pvc jupyterhub-nb-admin-pvc -n redhat-ods-applications  --ignore-not-found

# After job-test succeed, testing it on the cluster is the last step before you push the test harness image.
cluster-test:
	oc delete pod $(TEST_HARNESS_NAME)-pod -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete job manifests-test-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc get sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) || $(MAKE) test-setup
	./hack/operator-test-harness-pod.sh create

	# oc run $(TEST_HARNESS_NAME)-pod --image=$(TEST_HARNESS_FULL_IMG_URL) --restart=Never --attach -i --tty --serviceaccount $(TEST_HARNESS_NAME)-sa -n $(TEST_NAMESPACE) --env=JOB_PATH=/home/prow-manifest-test-job-pvc.yaml

cluster-test-clean:
	./hack/operator-test-harness-pod.sh delete
	oc delete sa $(MANIFESTS_NAME)-sa -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete rolebinding $(MANIFESTS_NAME)-rb -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete job manifests-test-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod -l job_name=$(MANIFESTS_NAME)-job -n $(TEST_NAMESPACE) --ignore-not-found
	oc delete pod jupyterhub-nb-admin  -n redhat-ods-applications --ignore-not-found --force --grace-period=0
	oc delete pvc jupyterhub-nb-admin-pvc -n redhat-ods-applications  --ignore-not-found
