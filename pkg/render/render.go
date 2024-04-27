package render

import (
	"fmt"
	"html/template"
	"log"
	"net/http"
)

// template cache
var tc = make(map[string]*template.Template)

func RenderTemplate(w http.ResponseWriter, t string) {
	var tmpl *template.Template
	var err error
	// check to see if the template is in the cache
	_, ok := tc[t]
	if !ok {
		// create template, read from disk, parse
		log.Println("creating template and adding to cache ", t)
		err = createTemplateCache(t)
		if err != nil {
			log.Println(err)
			return
		}
	} else {
		// we have the template in the cache
		log.Println("using template from cache ", t)
	}
	tmpl = tc[t]
	err = tmpl.Execute(w, nil)

	if err != nil {
		log.Println(err)
		return
	}
}

func createTemplateCache(t string) error {
	templates := []string{
		fmt.Sprintf("./templates/%s", t),
		"./templates/base.layout.tmpl",
	}
	// parse the template
	tmpl, err := template.ParseFiles(templates...)
	if err != nil {
		return err
	}

	// add template to cache
	tc[t] = tmpl
	return nil
}
