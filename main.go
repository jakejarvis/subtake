package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/jakejarvis/subtake/subtake"
)

func main() {
	configFile := "fingerprints.json"

	o := subtake.Options{}

	flag.StringVar(&o.Domains, "f", "", "Path to domains file")
	flag.IntVar(&o.Threads, "t", 10, "Number of concurrent threads")
	flag.IntVar(&o.Timeout, "timeout", 10, "Seconds to wait before connection timeout")
	flag.BoolVar(&o.Ssl, "ssl", false, "Force HTTPS connections")
	flag.BoolVar(&o.All, "a", false, "Send requests to every URL, even without identified CNAME")
	flag.BoolVar(&o.Verbose, "v", false, "Display all results including not vunerable URLs")
	flag.StringVar(&o.Output, "o", "", "Output results to specified file (writes JSON if file ends with '.json')")
	flag.StringVar(&o.Config, "c", configFile, "Path to configuration file")

	flag.Parse()

	flag.Usage = func() {
		fmt.Printf("Usage of %s:\n", os.Args[0])
		flag.PrintDefaults()
	}

	if flag.NFlag() == 0 {
		flag.Usage()
		os.Exit(1)
	}

	subtake.Process(&o)
}
