package main

import (
	"github.com/inconshreveable/log15"
	"gopkg.in/alecthomas/kingpin.v2"
	"os"
)

var (
	logger = log15.New()

	app = kingpin.
		New("hello", "Hello, World!").
		Version(VersionString("hello")).
		DefaultEnvars()
)

func invoke(args ...string) (string, error) {
	addArgs(app)
	return app.Parse(args)
}

func main() {
	_, err := invoke(os.Args[1:]...)
	if err != nil {
		app.Fatalf("%s", err)
	}
}
