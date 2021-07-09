package prow_operator_test_harness

import (
	"path/filepath"
	"testing"

	"github.com/Jooho/operator-test-harness/pkg/metadata"
	. "github.com/onsi/ginkgo"
	"github.com/onsi/ginkgo/reporters"
	. "github.com/onsi/gomega"

	_ "github.com/Jooho/operator-test-harness/pkg/tests"
)

const (
	testResultsDirectory = "/test-run-results"
	jUnitOutputFilename  = "junit-operator.xml"
	addonMetadataName    = "addon-metadata.json"
)

func TestOperatorTestHarness(t *testing.T) {
	RegisterFailHandler(Fail)
	jUnitReporter := reporters.NewJUnitReporter(filepath.Join(testResultsDirectory, jUnitOutputFilename))

	RunSpecsWithDefaultAndCustomReporters(t, "Operator Test Harness", []Reporter{jUnitReporter})

	err := metadata.Instance.WriteToJSON(filepath.Join(testResultsDirectory, addonMetadataName))
	if err != nil {
		t.Errorf("error while writing metadata: %v", err)
	}
}
