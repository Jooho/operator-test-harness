package tests

import (
	"context"
	"crypto/tls"
	"flag"
	"fmt"
	"net/http"
	"path/filepath"
	"time"

	"github.com/Jooho/operator-test-harness/pkg/metadata"
	"github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"k8s.io/apiextensions-apiserver/pkg/client/clientset/clientset"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"

	routev1 "github.com/openshift/api/route/v1"
	routeclientset "github.com/openshift/client-go/route/clientset/versioned/typed/route/v1"
	corev1 "k8s.io/api/core/v1"
)

var config *rest.Config

func init() {
	// Try inClusterConfig, fallback to using ~/.kube/config
	runtimeConfig, err := rest.InClusterConfig()
	if err != nil {
		var kubeconfig *string

		if home := homedir.HomeDir(); home != "" {
			kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
		} else {
			kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
		}
		// use the current context in kubeconfig
		config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)
		if err != nil {
			panic(err.Error())
		}
	} else {
		config = runtimeConfig
	}

}

var _ = ginkgo.BeforeSuite(func() {
	defer ginkgo.GinkgoRecover()
	fmt.Println("---------------------------------------")
	fmt.Println("Wait for Jupyterhub notebook is ready.")
	fmt.Println("...")
	fmt.Println("")

	// Get Route Host
	routeClientset, err := routeclientset.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}
	jupyterRoute := &routev1.Route{}
	for {
		tempJupyterRoute, err := routeClientset.Routes("redhat-ods-applications").Get(context.Background(), "jupyterhub", metav1.GetOptions{})
		if err != nil {
			fmt.Println("-------------")
			fmt.Printf("Jupyterhub route does not exist: %v\n", err)
			fmt.Println("Check it again after 5 secs")
			fmt.Println("")
			time.Sleep(10 * time.Second)
		} else {
			jupyterRoute = tempJupyterRoute
			fmt.Println("Jupyterhub route created")
			break
		}
	}

	jupyterRouteHost := jupyterRoute.Spec.Host
	// fmt.Printf("%v", jupyterRoute.Spec.Host)

	//Wait until Jupyterhub route return 200 OK
	transCfg := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, // ignore expired SSL certificates
	}
	client := &http.Client{Transport: transCfg}

	for {
		response, err := client.Get("https://" + jupyterRouteHost)
		if err != nil {
			fmt.Printf("%v", err)
		}

		if response.StatusCode == http.StatusOK {
			fmt.Println("Juypterhub is Ready so test starts")
			break
		} else {
			fmt.Println("-------------")
			fmt.Println("Juypterhub is not Ready")
			fmt.Printf("Jupyter notebook URL response code: %v\n", response.StatusCode)
			fmt.Println("Check it again after 5 secs")
			fmt.Println("")
			time.Sleep(10 * time.Second)
		}
	}
})

var _ = ginkgo.Describe("Default Operator Tests:", func() {

	ginkgo.It("nfsprovisioners.cache.jhouse.com CRD exists", func() {
		apiextensions, err := clientset.NewForConfig(config)
		Expect(err).NotTo(HaveOccurred())

		// Make sure the CRD exists
		_, err = apiextensions.ApiextensionsV1beta1().CustomResourceDefinitions().Get(context.TODO(), "nfsprovisioners.cache.jhouse.com", metav1.GetOptions{})

		if err != nil {
			metadata.Instance.FoundCRD = false
		} else {
			metadata.Instance.FoundCRD = true
		}

		Expect(err).NotTo(HaveOccurred())
	})

	ginkgo.It("Make sure all Pods are running in 5 mins", func() {

		clientset, err := kubernetes.NewForConfig(config)
		Expect(err).NotTo(HaveOccurred())
		var checkErr error = nil
		retry := 0

		for retry <= 4 {
			fmt.Printf("%d Retry to check pods status(every 1m)", retry)
			result, pod := CheckPodStatus(clientset)
			if result {
				break
			}

			if retry == 4 {
				checkErr = fmt.Errorf("Pod is not running : %v", pod)
			}else{			
				time.Sleep(60 * time.Second)
			}
			retry = retry + 1

		}

		if checkErr != nil {
			metadata.Instance.AllPodRunning = false
		} else {
			metadata.Instance.AllPodRunning = true
		}

		Expect(err).NotTo(HaveOccurred())

	})


})

func CheckPodStatus(clientset *kubernetes.Clientset) (bool, corev1.Pod) {
	pods, err := clientset.CoreV1().Pods("nfs-operator-test-harness").List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		panic(err.Error())
	}

	for _,pod := range pods.Items {
		if pod.Status.Phase != corev1.PodRunning {
			return false, pod
		}
	}
	return true, corev1.Pod{}

}
