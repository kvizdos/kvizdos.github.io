---
Title: "Getting the output of govulncheck"
Date: 05/20/2025
Summary: "A quick attempt at getting data out of govulncheck for usage in Go apps."
Author: Kenton Vizdos
Tags: Snippets
---

This is a small snippet showcasing a possibility of getting data out of govulncheck for usage in Go apps. [It was inspired by this Bluesky thread](https://bsky.app/profile/luxifer.fr/post/3lpmn2wtnvc2m).

For demo purposes, run with `GOTOOLCHAIN=go1.24.1 go run main.go` to get the http request smuggling vuln.

Take the "not production quality" warning to heart. This is not production quality code, but it's a good starting point for exploring the capabilities of govulncheck.

## main.go
```go
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/vuln/scan"
)

type trace struct {
	Module  string `json:"module"`
	Package string `json:"package,omitempty"`
	Version string `json:"version"`
}

type Finding struct {
	OSV          string  `json:"osv"`
	FixedVersion string  `json:"fixed_version"`
	Trace        []trace `json:"trace"`
}

type OSVEntry struct {
	SchemaVersion string   `json:"schema_version"`
	ID            string   `json:"id"`
	Modified      string   `json:"modified"`
	Published     string   `json:"published"`
	Aliases       []string `json:"aliases"`
	Summary       string   `json:"summary"`
	Details       string   `json:"details"`
	Affected      []struct {
		Package struct {
			Name      string `json:"name"`
			Ecosystem string `json:"ecosystem"`
		} `json:"package"`
		Ranges []struct {
			Type   string `json:"type"`
			Events []struct {
				Introduced string `json:"introduced,omitempty"`
				Fixed      string `json:"fixed,omitempty"`
			} `json:"events"`
		} `json:"ranges"`
		EcosystemSpecific struct {
			Imports []struct {
				Path    string   `json:"path"`
				Symbols []string `json:"symbols"`
			} `json:"imports"`
		} `json:"ecosystem_specific"`
	} `json:"affected"`
	References []struct {
		Type string `json:"type"`
		URL  string `json:"url"`
	} `json:"references"`
	Credits []struct {
		Name string `json:"name"`
	} `json:"credits"`
	DatabaseSpecific struct {
		URL          string `json:"url"`
		ReviewStatus string `json:"review_status"`
	} `json:"database_specific"`
}

type wrapper struct {
	Finding *Finding  `json:"finding"`
	OSV     *OSVEntry `json:"osv"`
}

func main() {
	fmt.Println(runtime.Version())
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "OK")
	})

	go func() {
		// This uses net/http’s internal chunked encoding parser
		// vulnerable to GO-2025-3563 in versions < 1.23.8 and < 1.24.2
		err := http.ListenAndServe(":8080", nil)
		if err != nil {
			panic(err)
		}
	}()

	// demo vuln
	_ = jwt.ClaimStrings{}

	osvMap := make(map[string]OSVEntry)

	var out bytes.Buffer

	cmd := scan.Command(context.Background(), "-json", "./...")
	cmd.Stdout = &out

	err := cmd.Start()
	if err == nil {
		err = cmd.Wait()
	}

	dec := json.NewDecoder(&out)
	dec.UseNumber()

	for dec.More() {
		var obj wrapper
		if err := dec.Decode(&obj); err != nil {
			fmt.Fprintln(os.Stderr, "failed to decode:", err)
			continue
		}

		if obj.OSV != nil {
			osvMap[obj.OSV.ID] = *obj.OSV
			continue
		}

		if obj.Finding == nil {
			continue
		}

		mappedVuln, ok := osvMap[obj.Finding.OSV]

		if !ok {
			log.Println("Couldn't find OSV", obj.Finding.OSV)
			continue
		}

		fmt.Println("--- VULN ---")
		fmt.Printf("Name: %s\n", mappedVuln.Summary)
		fmt.Printf("Fixed in: %s\n", obj.Finding.FixedVersion)
		printTrace(obj.Finding.Trace)
		fmt.Println("--- END VULN ---")
	}

	switch err := err.(type) {
	case nil:
	case interface{ ExitCode() int }:
		os.Exit(err.ExitCode())
	default:
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func printTrace(trace []trace) {
	for i, t := range trace {
		if t.Package != "" {
			fmt.Printf("  [%d] %s@%s (%s)\n", i+1, t.Package, t.Version, t.Module)
		} else {
			fmt.Printf("  [%d] %s@%s\n", i+1, t.Module, t.Version)
		}
	}
}
```

## go.mod
```mod
module github.com/kvizdos/vulncheck-test
go 1.24.1
toolchain go1.23.0
require golang.org/x/vuln v1.1.4
require (
	github.com/golang-jwt/jwt/v5 v5.2.1 // indirect
	golang.org/x/mod v0.22.0 // indirect
	golang.org/x/sync v0.10.0 // indirect
	golang.org/x/sys v0.29.0 // indirect
	golang.org/x/telemetry v0.0.0-20240522233618-39ace7a40ae7 // indirect
	golang.org/x/tools v0.29.0 // indirect
)
```
