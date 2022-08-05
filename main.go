package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	fileServer := http.FileServer(http.Dir("./static"))
	http.Handle("/", fileServer)

	portEnv := os.Getenv("PORT")
	if portEnv == "" {
		portEnv = "3000"
	}

	fmt.Printf("Starting server at: http://localhost:" + portEnv + "\n")
	if err := http.ListenAndServe(":"+portEnv, nil); err != nil {
		log.Fatal(err)
	}
}
