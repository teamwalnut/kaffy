package certificateProvisioner

import (
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"encoding/pem"

	"github.com/go-acme/lego/v4/certcrypto"
	"github.com/go-acme/lego/v4/certificate"
	"github.com/go-acme/lego/v4/challenge/http01"
	"github.com/go-acme/lego/v4/lego"
	"github.com/go-acme/lego/v4/registration"
)

// letsencrypt registration user
type letsencryptUser struct {
	Email        string
	Registration *registration.Resource
	key          crypto.PrivateKey
}

func (u *letsencryptUser) GetEmail() string {
	return u.Email
}
func (u *letsencryptUser) GetRegistration() *registration.Resource {
	return u.Registration
}
func (u *letsencryptUser) GetPrivateKey() crypto.PrivateKey {
	return u.key
}

// certificate intermediatory format
type Certificate struct {
	Certificate      []byte
	CertificateChain []byte
	PrivateKey       []byte
}

// letsencrypt environment
type Environment string

const (
	Prod    Environment = lego.LEDirectoryProduction
	Staging Environment = lego.LEDirectoryStaging
)

// ObtainCertificate request a certificate from letsencrypt
func ObtainCertificate(domains []string, email, challengePort *string, env Environment) (*Certificate, error) {
	privateKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, err
	}

	user := letsencryptUser{
		Email: *email,
		key:   privateKey,
	}

	config := lego.NewConfig(&user)

	config.CADirURL = string(env)
	config.Certificate.KeyType = certcrypto.RSA2048

	// A client facilitates communication with the CA server.
	client, err := lego.NewClient(config)
	if err != nil {
		return nil, err
	}

	// spin an http-01 challenge server
	err = client.Challenge.SetHTTP01Provider(http01.NewProviderServer("", *challengePort))
	if err != nil {
		return nil, err

	}

	user.Registration, err = client.Registration.Register(registration.RegisterOptions{TermsOfServiceAgreed: true})
	if err != nil {
		return nil, err
	}

	request := certificate.ObtainRequest{
		Domains: domains,
		Bundle:  true,
	}

	certificates, err := client.Certificate.Obtain(request)
	if err != nil {
		return nil, err
	}

	certificate, err := parseCertificates(certificates)
	if err != nil {
		return nil, err
	}

	return certificate, nil
}

// parse letsencrypt certificate to intermediatory format
func parseCertificates(rawCertificate *certificate.Resource) (*Certificate, error) {
	certChain := decodePem(rawCertificate.Certificate)
	var certificate Certificate
	certificate.PrivateKey = rawCertificate.PrivateKey

	conf := tls.Config{}
	conf.RootCAs = x509.NewCertPool()

	for _, cert := range certChain.Certificate {
		x509Cert, err := x509.ParseCertificate(cert)
		if err != nil {
			return nil, err
		}

		b := pem.Block{Type: "CERTIFICATE", Bytes: cert}
		certPEM := pem.EncodeToMemory(&b)
		if !x509Cert.IsCA {
			certificate.Certificate = certPEM
			continue
		}

		certificate.CertificateChain = append(certificate.CertificateChain, certPEM...)
	}

	return &certificate, nil
}

// decode PEM to known certificate format
func decodePem(certInput []byte) tls.Certificate {
	var cert tls.Certificate
	certPEMBlock := certInput
	var certDERBlock *pem.Block
	for {
		certDERBlock, certPEMBlock = pem.Decode(certPEMBlock)
		if certDERBlock == nil {
			break
		}
		if certDERBlock.Type == "CERTIFICATE" {
			cert.Certificate = append(cert.Certificate, certDERBlock.Bytes)
		}
	}
	return cert
}
