package main

import (
	"fmt"
	"net/http"

	"github.com/celtic01/hotel-app/pkg/handlers"
)

const portNumber = ":8080"

func main() {
	http.HandleFunc("/", handlers.Home)
	http.HandleFunc("/about", handlers.About)

	fmt.Printf("Starting application on port %s", portNumber)

	http.ListenAndServe(portNumber, nil)
}
