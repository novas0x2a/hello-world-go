//go:generate make version.go

package main

import (
	"fmt"
)

var (
	softwareVersion = "0.0.1-dev"
	buildID         string

	releaseBuildString string
	releaseBuild       bool
)

func init() {
	if buildID == "" {
		buildID = "dev+XXXXXX"
		releaseBuild = false
	} else {
		releaseBuild = (releaseBuildString == "true")
	}
}

// Version is the version of the software
func Version() string {
	return softwareVersion
}

// PackageVersion the version of the software, including any build ids
func PackageVersion() string {
	return softwareVersion + "+" + buildID
}

// ReleaseBuild returns whether this is a release build
func ReleaseBuild() bool {
	return releaseBuild
}

// VersionString returns a string suitable for a --version flag
func VersionString(tool string) string {
	if releaseBuild {
		return fmt.Sprintf("%s %s (RELEASE: %s) ",
			tool, Version(), PackageVersion())
	}
	return fmt.Sprintf("%s %s (DEV) ", tool, PackageVersion())
}
