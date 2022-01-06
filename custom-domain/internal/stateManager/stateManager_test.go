package stateManager

import (
	"encoding/json"
	"testing"
	"time"
)

var stateFile = "{\"domains\":[\"example.com\"],\"last_updated\":\"2021-09-09T16:52:47.22903+03:00\",\"certificate_arn\":\"arn:aws:acm:us-west-2:981096228685:certificate/1e45a1d9-bbbc-4a18-9a16-061b7526f0bc\"}"

func TestShouldRenewCertificateNotRenew(t *testing.T) {
	var state State
	if err := json.Unmarshal([]byte(stateFile), &state); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	domains := []string{"example.com"}

	now, err := time.Parse(time.RFC3339, "2021-09-09T16:52:47.22903+03:00")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	shouldNotRenew := ShouldRenewCertificate(&state, domains, now)
	if shouldNotRenew {
		t.Errorf("ShouldRenewCertificate should return false for input state: %s domains: %s date: %s", stateFile, domains, now)
	}
}

func TestShouldRenewCertificateRenewExpired(t *testing.T) {
	var state State
	if err := json.Unmarshal([]byte(stateFile), &state); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	domains := []string{"example.com"}

	now, err := time.Parse(time.RFC3339, "2021-11-09T16:52:47.22903+03:00")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	shouldRenew := ShouldRenewCertificate(&state, domains, now)
	if !shouldRenew {
		t.Errorf("ShouldRenewCertificate should return true for input state: %s domains: %s date: %s", stateFile, domains, now)
	}
}

func TestShouldRenewCertificateRenewDomains(t *testing.T) {
	var state State
	if err := json.Unmarshal([]byte(stateFile), &state); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	domains := []string{"example.com", "test.example.com"}

	now, err := time.Parse(time.RFC3339, "2021-09-09T16:52:47.22903+03:00")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	shouldRenew := ShouldRenewCertificate(&state, domains, now)
	if !shouldRenew {
		t.Errorf("ShouldRenewCertificate should return true for input state: %s domains: %s date: %s", stateFile, domains, now)
	}
}

func TestIsListEqualFalse(t *testing.T) {
	list1 := []string{"example.com", "test.example.com", "demo.example.com", "play.example.com"}
	list2 := []string{"example.com", "best.example.com", "demo.example.com", "play.example.com"}

	equals := isListsEqual(list1, list2)

	if equals {
		t.Errorf("isListEqual should return false for lists %s and %s", list1, list2)
	}
}

func TestIsListEqualTrue(t *testing.T) {
	list1 := []string{"example.com", "test.example.com", "demo.example.com", "play.example.com"}
	list2 := []string{"test.example.com", "example.com", "play.example.com", "demo.example.com"}

	equals := isListsEqual(list1, list2)

	if !equals {
		t.Errorf("isListEqual should return true for lists %s and %s", list1, list2)
	}
}
