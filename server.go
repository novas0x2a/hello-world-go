package main

import (
	"fmt"
	"github.com/satori/go.uuid"
	"gopkg.in/alecthomas/kingpin.v2"
	"net/http"
)

type (
	// HelloServer just holds the server, man
	HelloServer struct {
		http.Server
		DefaultSender string
	}
)

func (server *HelloServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	token := uuid.NewV4().String()

	logger.Info("request", "token", token, "host", r.RemoteAddr, "proto", r.Proto, "method", r.Method, "path", r.RequestURI)

	if r.URL.Path != "/" {
		logger.Warn("reply", "token", token, "code", 404)
		http.NotFound(w, r)
		return
	}

	from := r.FormValue("from")
	to := r.FormValue("to")

	if from == "" {
		from = server.DefaultSender
	}

	if to != "" {
		fmt.Fprintf(w, "%s, ", to)
	}

	fmt.Fprintf(w, "%s says Hello to you!", from)
	logger.Info("reply", "token", token, "code", 200)
}

func addArgs(app *kingpin.Application) {
	server := HelloServer{}
	app.
		Flag("bind", "where to bind").
		Default(":http").
		Short('b').
		StringVar(&server.Addr)

	app.
		Flag("default-sender", "Who is the default greeter?").
		Default("Hal").
		StringVar(&server.DefaultSender)

	app.Action(func(c *kingpin.ParseContext) error {
		logger.Info("Starting up!", "version", VersionString("hello"), "bind", server.Addr)

		if server.Handler == nil {
			mux := http.NewServeMux()
			mux.Handle("/", &server)
			server.Handler = mux
		}

		return server.ListenAndServe()
	})
}
