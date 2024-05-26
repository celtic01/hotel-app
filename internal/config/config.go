package config

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"text/template"

	"github.com/alexedwards/scs/v2"
	"github.com/celtic01/hotel-app/internal/models"
	"github.com/joho/godotenv"
)

// AppConfig holds the application config
type AppConfig struct {
	UseCache      bool
	TemplateCache map[string]*template.Template
	InfoLog       *log.Logger
	ErrorLog      *log.Logger
	InProduction  bool
	Session       *scs.SessionManager
	MailChan      chan models.MailData
}

type Env struct {
	Port     string
	InProd   bool
	UseCache bool
	DBHost   string
	DBUser   string
	DBPass   string
	DBName   string
}

func (e *Env) GetEnvFile() {
	e.InProd, _ = strconv.ParseBool(os.Getenv("IN_PROD"))
	fmt.Println("InProd:", e.InProd)
	if !e.InProd {
		err := godotenv.Load("/Users/andreibortas/Desktop/Workspace/hotel-reservation/internal/config/.env")
		if err != nil {
			log.Fatal("Error loading .env file")
		}
		e.GetEnv()
		e.DBPass = os.Getenv("DB_PASS")
		e.DBUser = os.Getenv("DB_USER")
	} else if e.InProd {
		credentialsJSON := os.Getenv("DB_CREDS")
		var credentials map[string]string

		err := json.Unmarshal([]byte(credentialsJSON), &credentials)

		if err != nil {
			log.Fatalf("Error parsing JSON: %v", err)
		}

		e.DBUser = credentials["username"]
		e.DBPass = credentials["password"]

		e.GetEnv()

	}
}

func (e *Env) GetEnv() {
	e.Port = os.Getenv("PORT")
	e.UseCache, _ = strconv.ParseBool(os.Getenv("USE_CACHE"))
	e.DBHost = os.Getenv("DB_HOST")
	e.DBName = os.Getenv("DB_NAME")

	if e.Port == "" {
		e.Port = ":8080"
	}
	if e.DBHost == "" {
		panic("DB_HOST is not set")
	}
	if e.DBName == "" {
		panic("DB_NAME is not set")
	}
}
