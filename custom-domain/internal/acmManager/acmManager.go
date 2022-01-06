package acmManager

import (
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/acm"
)

// ImportCertificate import a certificate created with letsencrypt
func ImportCertificate(certificate, certificateChain, privateKey []byte, awsRegion *string) (string, error) {
	acmInput := acm.ImportCertificateInput{
		Certificate:      certificate,
		CertificateChain: certificateChain,
		PrivateKey:       privateKey,
	}

	session, err := session.NewSession(&aws.Config{
		Region: awsRegion,
	})
	if err != nil {
		return "", err
	}

	acmClient := acm.New(session)

	res, err := acmClient.ImportCertificate(&acmInput)
	if err != nil {
		return "", err
	}
	return *res.CertificateArn, nil
}

// DeleteCertificate delete a previous certificate
func DeleteCertificate(certificateArn, awsRegion *string) error {
	session, err := session.NewSession(&aws.Config{
		Region: awsRegion,
	})

	if err != nil {
		return err
	}

	acmClient := acm.New(session)

	for {
		res, err := acmClient.DescribeCertificate(&acm.DescribeCertificateInput{
			CertificateArn: certificateArn,
		})
		if err != nil {
			return err
		}

		if len(res.Certificate.InUseBy) > 0 {
			time.Sleep(time.Second)
			continue
		}
		break
	}

	if _, err := acmClient.DeleteCertificate(&acm.DeleteCertificateInput{
		CertificateArn: certificateArn,
	}); err != nil {
		return err
	}

	return nil
}
