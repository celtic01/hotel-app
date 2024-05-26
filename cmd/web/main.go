package main

import (
	"encoding/gob"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/alexedwards/scs/v2"
	"github.com/celtic01/hotel-app/internal/config"
	"github.com/celtic01/hotel-app/internal/driver"
	"github.com/celtic01/hotel-app/internal/handlers"
	"github.com/celtic01/hotel-app/internal/helpers"
	"github.com/celtic01/hotel-app/internal/models"
	"github.com/celtic01/hotel-app/internal/render"
)

var app config.AppConfig
var env config.Env

var session *scs.SessionManager

func main() {

	env.GetEnvFile()
	db, err := run()
	if err != nil {
		log.Fatal(err)
	}
	defer db.SQL.Close()
	defer close(app.MailChan)

	fmt.Println("Starting mail listener")
	listenForMail()

	fmt.Printf("Starting application on port %s", env.Port)

	srv := &http.Server{
		Addr:    env.Port,
		Handler: routes(&app),
	}

	err = srv.ListenAndServe()
	log.Fatal(err)
}

func run() (*driver.DB, error) {
	gob.Register(models.Reservation{})
	gob.Register(models.User{})
	gob.Register(models.Room{})
	gob.Register(models.Restriction{})
	gob.Register(map[string]int{})

	mailChan := make(chan models.MailData)
	app.MailChan = mailChan
	app.InProduction = env.InProd

	infoLog := log.New(os.Stdout, "INFO\t", log.Ldate|log.Ltime)
	errorLog := log.New(os.Stdout, "ERROR\t", log.Ldate|log.Ltime|log.Lshortfile)
	app.InfoLog = infoLog
	app.ErrorLog = errorLog

	session = scs.New()
	session.Lifetime = 24 * time.Hour
	session.Cookie.Persist = true
	session.Cookie.SameSite = http.SameSiteLaxMode
	session.Cookie.Secure = app.InProduction

	app.Session = session

	// connect to database
	log.Println("Connecting to database...")
	fmt.Println(env.DBHost, env.DBName, env.DBUser, env.DBPass)
	db, err := driver.ConnectSQL(fmt.Sprintf("host=%s port=5432 dbname=%s user=%s password=%s sslmode=disable", env.DBHost, env.DBName, env.DBUser, env.DBPass))

	if err != nil {
		log.Fatal("cannot connect to database! Dying...")
	}
	log.Println("Connected to database")

	tc, err := render.CreateTemplateCache()
	if err != nil {
		log.Fatal("cannot create template cache")
		return nil, err
	}

	app.TemplateCache = tc
	app.UseCache = false

	repo := handlers.NewRepo(&app, db)

	handlers.NewHandlers(repo)
	render.NewRenderer(&app)
	helpers.NewHelpers(&app)

	return db, nil
}
