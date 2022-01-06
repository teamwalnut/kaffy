package stateManager

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"sort"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/google/uuid"
)

// State represent the remote state of custom domains
type State struct {
	Domains        []string  `json:"domains"`
	LastUpdated    time.Time `json:"last_updated"`
	CertificateArn string    `json:"certificate_arn"`
}

// TestUsability test if the bucket is reachable and accessible
func TestUsability(bucketName, key, awsRegion string) error {
	session, err := session.NewSession(&aws.Config{
		Region: &awsRegion,
	})
	if err != nil {
		return err
	}

	s3Client := s3.New(session)
	uuidInstance := uuid.New().String()
	testKey := fmt.Sprintf("%s.%s", key, uuidInstance)
	if _, err := s3Client.PutObject(&s3.PutObjectInput{
		Key:    &testKey,
		Bucket: &bucketName,
	}); err != nil {
		return fmt.Errorf("failed to put object: %v", err)
	}

	if _, err := s3Client.GetObject(&s3.GetObjectInput{
		Key:    &testKey,
		Bucket: &bucketName,
	}); err != nil {
		return fmt.Errorf("failed to get object: %v", err)
	}

	if _, err := s3Client.DeleteObject(&s3.DeleteObjectInput{
		Key:    &testKey,
		Bucket: &bucketName,
	}); err != nil {
		return fmt.Errorf("failed to delete object: %v", err)
	}

	return nil
}

// RetrieveState return the state saved to s3
func RetrieveState(bucketName, key, awsRegion *string) (*State, error) {
	session, err := session.NewSession(&aws.Config{
		Region: awsRegion,
	})
	if err != nil {
		return nil, err
	}

	s3Client := s3.New(session)
	obj, err := s3Client.GetObject(&s3.GetObjectInput{
		Bucket: bucketName,
		Key:    key,
	})

	if err != nil {
		return nil, err
	}

	defer obj.Body.Close()

	objContent, err := ioutil.ReadAll(obj.Body)
	if err != nil {
		return nil, err
	}

	var state State
	if err := json.Unmarshal(objContent, &state); err != nil {
		return nil, err
	}

	return &state, nil
}

// SaveState saves the state to the bucket
func SaveState(bucketName, key, awsRegion *string, state *State) error {
	json, err := json.Marshal(state)
	if err != nil {
		return err
	}

	session, err := session.NewSession(&aws.Config{
		Region: awsRegion,
	})
	if err != nil {
		return err
	}

	s3Client := s3.New(session)
	s3Client.PutObject(&s3.PutObjectInput{
		Body:   aws.ReadSeekCloser(bytes.NewReader(json)),
		Key:    key,
		Bucket: bucketName,
	})

	return nil
}

// ShouldRenewCertificate return true if certificate should be renewed
func ShouldRenewCertificate(state *State, domains []string, date time.Time) bool {

	if len(domains) == 0 {
		return false
	}

	// if LastUpdated is zero means there is no certificate
	if state.LastUpdated.IsZero() {
		return true
	}

	twoMonths := 60 * 24 * time.Hour
	if state.LastUpdated.Add(twoMonths).Before(date) {
		return true
	}

	if !isListsEqual(state.Domains, domains) {
		return true
	}

	return false
}

// compare 2 lists
func isListsEqual(stateList, dbList []string) bool {
	sort.Strings(stateList)
	sort.Strings(dbList)

	if len(stateList) == len(dbList) {
		for i, v := range stateList {
			if v != dbList[i] {
				return false
			}
		}
	} else {
		return false
	}

	return true
}
