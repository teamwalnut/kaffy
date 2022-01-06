package albManager

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/elbv2"
)

// UpdateListenerCertificates update loadbalancer certificate
func UpdateListenerCertificates(newCertificateArn, oldCertificateArn, listenerArn, awsRegion string) error {
	session, err := session.NewSession(&aws.Config{
		Region: &awsRegion,
	})
	if err != nil {
		return err
	}

	elbv2Client := elbv2.New(session)

	if _, err := elbv2Client.AddListenerCertificates(&elbv2.AddListenerCertificatesInput{
		ListenerArn: &listenerArn,
		Certificates: []*elbv2.Certificate{
			{
				CertificateArn: &newCertificateArn,
			},
		},
	}); err != nil {
		return err
	}

	if oldCertificateArn != "" {
		if _, err := elbv2Client.RemoveListenerCertificates(&elbv2.RemoveListenerCertificatesInput{
			ListenerArn: &listenerArn,
			Certificates: []*elbv2.Certificate{
				{
					CertificateArn: &oldCertificateArn,
				},
			},
		}); err != nil {
			return err
		}
	}

	return nil
}
