package utils

import (
	"github.com/spf13/viper"
)

func GetEnvWithDefault(conf *viper.Viper, key, defaultValue string) string {

	conf.BindEnv(key)
	if defaultValue != "" && conf.GetString(key) == "" {
		conf.Set(key, defaultValue)
	}
	return conf.GetString(key)
}
