package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"

	git "gopkg.in/src-d/go-git.v4"
)

func main() {
	port := flag.Int("port", 9170, "http port")
	debug := flag.Bool("debug", false, "enable debugging")
	flag.Parse()
	if flag.NArg() != 1 {
		log.Fatal("missing git repo path in commandline arguments")
	}

	repo, err := git.PlainOpen(flag.Arg(0))
	if err != nil {
		log.Fatal(err)
	}

	worktree, err := repo.Worktree()
	if err != nil {
		log.Fatal(err)
	}

	getStatus := func() string {
		status, err := worktree.Status()
		if err != nil {
			log.Fatal(err)
		}

		if *debug {
			for name, fileStatus := range status {

				log.Printf(
					"Path: %s, Staging Status: %s, Worktree Status: %s, Extra Status: %s\n",
					name,
					string(fileStatus.Staging),
					string(fileStatus.Worktree),
					string(fileStatus.Extra),
				)
			}
		}

		jsonStatus, err := json.Marshal(status)
		if err != nil {
			log.Println(err)
		}

		return string(jsonStatus)
	}

	handleGetStatus := func(res http.ResponseWriter, req *http.Request) {
		status := getStatus()
		if *debug {
			log.Println(*req)
			res.Header().Set("Access-Control-Allow-Origin", "*")
			log.Println(status)
		}
		res.Header().Set("Content-Type", "application/json")

		io.WriteString(res, status)
	}

	http.HandleFunc("/", handleGetStatus)

	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", *port), nil))
}
