package dbrepo

import (
	"database/sql"

	"github.com/celtic01/hotel-app/internal/config"
	"github.com/celtic01/hotel-app/internal/repository"
)

type postgresDBRepo struct {
	App *config.AppConfig
	DB  *sql.DB
}

func NewPostgresRepo(a *config.AppConfig, db *sql.DB) repository.DatabaseRepo {
	return &postgresDBRepo{
		App: a,
		DB:  db,
	}
}
