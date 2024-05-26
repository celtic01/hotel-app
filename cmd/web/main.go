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

const portNumber = ":8080"

var session *scs.SessionManager

func main() {

	db, err := run()
	if err != nil {
		log.Fatal(err)
	}
	defer db.SQL.Close()
	defer close(app.MailChan)

	fmt.Println("Starting mail listener")
	listenForMail()

	fmt.Printf("Starting application on port %s", portNumber)

	srv := &http.Server{
		Addr:    portNumber,
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
	/* flags/envs
	    inProduction
		useCache
		dbName
		dbUser
		dbPass
		dbHost
		dbPort
	*/
	app.InProduction = false

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
	db, err := driver.ConnectSQL("host=postgresql-hotel.cdfrsad3v3po.us-west-2.rds.amazonaws.com port=5432 dbname=hotelreservationproduction user=hotelapp password=>!TxIEdo~_)tw$XhI?zB_tC3ow3S")
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
