package utils

import (
	"os"
	"testing"

	"github.com/spf13/viper"
)

func TestGetEnvironmentFallback(t *testing.T) {
	defaultValue := "defaultString"
	conf := viper.New()
	value := GetEnvWithDefault(conf, "empty-key", defaultValue)
	if value != defaultValue {
		t.Errorf("GetEnv should return the default value for empty key")
	}
}

func TestGetEnvironmentValue(t *testing.T) {
	defaultValue := "defaultString"
	testValue := "testing-value"
	os.Setenv("TEST_KEY", testValue)
	conf := viper.New()
	value := GetEnvWithDefault(conf, "TEST_KEY", defaultValue)
	if value != testValue {
		t.Errorf("GetEnv should return the value for non-empty key")
	}
}
