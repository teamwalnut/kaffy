package main

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	"github.com/jackc/pgx/v4/pgxpool"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"

	"github.com/teamwalnut/walnut_monorepo/api/custom-domain/internal/acmManager"
	"github.com/teamwalnut/walnut_monorepo/api/custom-domain/internal/albManager"
	"github.com/teamwalnut/walnut_monorepo/api/custom-domain/internal/certificateProvisioner"
	"github.com/teamwalnut/walnut_monorepo/api/custom-domain/internal/dataStore"
	"github.com/teamwalnut/walnut_monorepo/api/custom-domain/internal/stateManager"
	"github.com/teamwalnut/walnut_monorepo/api/custom-domain/internal/utils"
)

var (
	conn  *pgxpool.Pool
	state *stateManager.State
	err   error
	conf  *viper.Viper
)

func handler(p *httputil.ReverseProxy) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		log.Info("serving well-known")
		p.ServeHTTP(w, r)
	}
}

func health(w http.ResponseWriter, r *http.Request) {
	if err := conn.Ping(context.Background()); err != nil {
		w.WriteHeader(500)
		log.WithError(err).Warn("db connectivity test failed")
		return
	}

	if err := stateManager.TestUsability(
		conf.GetString("state-bucket"),
		conf.GetString("state-file-path"),
		conf.GetString("aws-region"),
	); err != nil {
		log.WithError(err).Warn("bucket connectivity test failed")
		w.WriteHeader(500)
		return
	}
	log.Info("ping!")
	w.WriteHeader(200)
}

func main() {
	conf = viper.New()
	conf.SetEnvPrefix("cdm")
	conf.SetEnvKeyReplacer(
		strings.NewReplacer("-", "_"),
	)

	// app config
	env := utils.GetEnvWithDefault(conf, "environment", "")
	port := utils.GetEnvWithDefault(conf, "port", "4000")

	// cert provisioning config
	email := utils.GetEnvWithDefault(conf, "email", "")
	challengePort := utils.GetEnvWithDefault(conf, "challenge-server-port", "5002")

	// cloud services config
	stateBucket := utils.GetEnvWithDefault(conf, "state-bucket", "")
	stateFilePath := utils.GetEnvWithDefault(conf, "state-file-path", "cdm/state.json")

	awsRegion := utils.GetEnvWithDefault(conf, "aws-region", "")
	listenerArn := utils.GetEnvWithDefault(conf, "listener-arn", "")

	// datastore config
	dbUser := utils.GetEnvWithDefault(conf, "db-user", "")
	dbPass := utils.GetEnvWithDefault(conf, "db-pass", "")
	dbHost := utils.GetEnvWithDefault(conf, "db-host", "")
	dbPort := utils.GetEnvWithDefault(conf, "db-port", "5432")
	dbName := utils.GetEnvWithDefault(conf, "db-name", "")

	log.SetFormatter(&log.JSONFormatter{})

	// letsencrypt environment
	letsencryptEnv := certificateProvisioner.Staging
	if env == "prod" {
		letsencryptEnv = certificateProvisioner.Prod
	}

	dbLog := log.WithFields(log.Fields{
		"host": dbHost,
		"port": dbPort,
		"user": dbUser,
		"name": dbName,
	})

	conn, err = dataStore.GetConnection(
		&dbUser,
		&dbPass,
		&dbName,
		&dbHost,
		&dbPort,
	)

	if err != nil {
		dbLog.WithError(err).Fatal("failed to connect to db")
	}

	target := fmt.Sprintf("http://localhost:%s", challengePort)
	remote, err := url.Parse(target)
	if err != nil {
		panic(err)
	}

	proxy := httputil.NewSingleHostReverseProxy(remote)

	router := mux.NewRouter()
	router.HandleFunc("/ping", health)
	router.PathPrefix("/.well-known/").HandlerFunc(handler(proxy))

	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", port),
		Handler: router,
	}

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	// start the http server
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	// retreive state file from bucket
	state, err = stateManager.RetrieveState(
		&stateBucket,
		&stateFilePath,
		&awsRegion,
	)
	if err != nil {
		log.WithFields(log.Fields{
			"bucket_name": stateBucket,
			"key":         stateFilePath,
		}).WithError(err).
			Warn("could not retrieve state from bucket")

		log.Info("creating a new state file")
		state = &stateManager.State{}
	} else {
		log.WithFields(log.Fields{
			"state_last_update": state.LastUpdated,
		}).Info("state file fetched")
	}

	// start the scheduler
	go func() {
		for {
			// run every minute
			time.Sleep(time.Minute)
			now := time.Now()

			// get the list of domains
			domains, err := dataStore.GetDomains(conn, &env)
			if err != nil {
				dbLog.WithError(err).Warn("could not retrieve domains from datastore")
			}
			dbLog.WithFields(log.Fields{
				"domains": domains,
				"env":     env,
			}).Info("domains fetched")

			if stateManager.ShouldRenewCertificate(state, domains, now) {
				cert, err := certificateProvisioner.ObtainCertificate(
					domains,
					&email,
					&challengePort,
					letsencryptEnv,
				)

				if err != nil {
					log.WithFields(log.Fields{
						"domain":                domains,
						"letsencrypt_env":       letsencryptEnv,
						"challenge_server_port": challengePort,
					}).WithError(err).
						Warn("failed to provision certificate")

					continue
				}

				// save certificate to amazon certificate manager
				certArn, err := acmManager.ImportCertificate(
					cert.Certificate,
					cert.CertificateChain,
					cert.PrivateKey,
					&awsRegion,
				)
				if err != nil {
					log.WithFields(log.Fields{
						"region":           awsRegion,
						"certificate":      string(cert.Certificate),
						"certificateChain": string(cert.CertificateChain),
						"privateKey":       string(cert.PrivateKey),
					}).WithError(err).
						Fatal("could not save certificate to acm")
				}

				log.WithFields(log.Fields{"arn": certArn}).
					Info("certificate save to acm")

				// update the loadbalancer certificate
				if err = albManager.UpdateListenerCertificates(
					certArn,
					state.CertificateArn,
					listenerArn,
					awsRegion,
				); err != nil {
					log.WithError(err).
						WithFields(log.Fields{
							"listener_arn": listenerArn,
						}).Fatal("failed to update listener certificate")
				}

				log.WithFields(log.Fields{
					"listener_arn": listenerArn,
				}).Info("listener's certificate updated")

				// delete the old certificate
				if state.CertificateArn != "" {
					if err := acmManager.DeleteCertificate(&state.CertificateArn, &awsRegion); err != nil {
						log.WithError(err).
							WithFields(log.Fields{"arn": state.CertificateArn}).
							Warning("could not delete old certificate")
					} else {
						log.WithFields(log.Fields{"arn": state.CertificateArn}).
							Info("old certificate deleted successfully")
					}
				}

				tmpState := stateManager.State{
					Domains:        domains,
					CertificateArn: certArn,
					LastUpdated:    time.Now(),
				}

				// update remote state
				if err = stateManager.SaveState(
					&stateBucket,
					&stateFilePath,
					&awsRegion,
					&tmpState,
				); err != nil {
					log.WithFields(log.Fields{
						"bucket_name": stateBucket,
						"key":         stateFilePath,
						"region":      awsRegion,
					}).Error("failed to save state")
				}

				// update local state copy
				state = &tmpState
			}
		}
	}()

	// interrupts handling
	<-done
	log.Print("Server Stopped")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer func() {
		// extra handling here
		cancel()
	}()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server Shutdown Failed:%+v", err)
	}
	log.Info("Server Exited Properly")
}
