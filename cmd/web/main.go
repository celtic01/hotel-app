package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/celtic01/hotel-app/pkg/config"
	"github.com/celtic01/hotel-app/pkg/handlers"
	"github.com/celtic01/hotel-app/pkg/render"
)

const portNumber = ":8080"

func main() {
	var app config.AppConfig
	tc, err := render.CreateTemplateCache()
	if err != nil {
		log.Fatal("cannot create template cache")
	}

	app.TemplateCache = tc

	render.NewTemplates(&app)

	http.HandleFunc("/home", handlers.Home)
	http.HandleFunc("/about", handlers.About)

	fmt.Printf("Starting application on port %s", portNumber)

	http.ListenAndServe(portNumber, nil)
}
