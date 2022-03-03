FROM registry.access.redhat.com/ubi8/go-toolset AS builder

USER root

ENV PKG=/go/src/github.com/%GIT_REPO_ORG%/%TEST_HARNESS_NAME%/
ENV HOME /tmp

WORKDIR ${PKG}
RUN chmod -R 755 ${PKG}

ADD https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.9.9/openshift-client-linux-4.9.9.tar.gz ${PKG}/oc.tar.gz 
RUN tar -C ${PKG}/ -xvf ${PKG}/oc.tar.gz 

# compile test binary
COPY . .
RUN make

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

RUN mkdir -p ${HOME} &&\
    chown 1001:0 ${HOME} &&\
    chmod ug+rwx ${HOME}

RUN mkdir -p /test-run-results &&\
    chown 1001:0 /test-run-results &&\
    chmod ug+rwx /test-run-results

COPY --from=builder /go/src/github.com/%GIT_REPO_ORG%/%TEST_HARNESS_NAME%/operator-test-harness.test  operator-test-harness.test
COPY --from=builder /go/src/github.com/Jooho/starburst-operator-test-harness/oc  /usr/local/bin/oc
RUN  chmod +x /usr/local/bin/oc

COPY env.sh /home/env.sh
COPY template/* /home/.
COPY ./hack/run-test.sh  /run-test.sh

RUN chmod +x run-test.sh
RUN chmod +x operator-test-harness.test

ENTRYPOINT [ "sh", "/run-test.sh" ]

USER 1001