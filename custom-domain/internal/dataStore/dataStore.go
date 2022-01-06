package dataStore

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v4/pgxpool"
)

// GetConnection create a connection to the database
func GetConnection(dbUser, dbPassword, dbName, dbHost, dbPort *string) (*pgxpool.Pool, error) {
	connString := fmt.Sprintf("user=%s password=%s host=%s port=%s dbname=%s sslmode=prefer", *dbUser, *dbPassword, *dbHost, *dbPort, *dbName)
	return pgxpool.Connect(context.Background(), connString)
}

// GetDomains retreive domains from database
func GetDomains(conn *pgxpool.Pool, env *string) ([]string, error) {
	// Execute the query
	query := fmt.Sprintf("SELECT domain FROM custom_domains WHERE env='%s'", *env)
	if rows, err := conn.Query(context.Background(), query); err != nil {
		return nil, err
	} else {
		defer rows.Close()

		var (
			domains []string
			domain  string
		)

		for rows.Next() {
			rows.Scan(&domain)
			domains = append(domains, domain)
		}
		if rows.Err() != nil {
			return nil, rows.Err()
		}

		return domains, nil
	}
}
