package main // import "github.com/arribada/smartconnect/tools/uploader"

import (
	"bytes"
	"crypto/tls"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"mime/multipart"

	"github.com/pkg/errors"

	"gopkg.in/alecthomas/kingpin.v2"
)

func main() {
	log.SetFlags(log.Ltime | log.Lshortfile)
	app := kingpin.New(filepath.Base(os.Args[0]), "The Prometheus benchmarking tool")
	app.HelpFlag.Short('h')
	f := app.Flag("file", "file to upload").
		Required().
		Short('f').
		ExistingFile()
	server := app.Flag("server", "server api url").
		Required().
		Short('s').
		String()
	user := app.Flag("user", "login username").
		Required().
		Short('u').
		String()
	pass := app.Flag("pass", "login pass").
		Required().
		Short('p').
		String()
	xmlType := app.Flag("type", "xml file type").
		Required().
		Short('t').
		String()
	ca := app.Flag("carea", "conservation area to upload the file to").
		Required().
		Short('c').
		String()

	if _, err := app.Parse(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, errors.Wrapf(err, "Error parsing commandline arguments"))
		app.Usage(os.Args[1:])
		os.Exit(2)
	}

	file, err := os.Open(*f)
	if err != nil {
		log.Fatalf("error reading the uploaded file %v : %v", *f, err)
	}
	fs, err := file.Stat()
	if err != nil {
		log.Fatalf("error getting file stats %v : %v", *f, err)
	}
	fSize := strconv.Itoa(int(fs.Size()))
	defer file.Close()

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{Transport: tr}
	body := []byte(`
	{
		"conservationArea":"` + *ca + `",
		"type":"` + *xmlType + `",
		"name":"` + *f + `"
	 }
	`)
	req, err := http.NewRequest("POST", *server+"/server/api/dataqueue/items/", bytes.NewBuffer(body))
	if err != nil {
		log.Fatal(err)
	}
	req.SetBasicAuth(*user, *pass)
	req.Header.Add("X-Upload-Content-Length", fSize)
	req.Header.Set("Content-Type", "application/json")
	res, err := client.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	if res.StatusCode != http.StatusOK {
		log.Fatalf("unexpected response status code:%v", res.StatusCode)
	}

	uploadURL, err := res.Location()
	if err != nil {
		log.Fatal(err)
	}
	res.Body.Close()

	// Make the actual request to upload the file.
	{
		body := &bytes.Buffer{}
		writer := multipart.NewWriter(body)
		part, err := writer.CreateFormFile("upload_file", filepath.Base(file.Name()))
		if err != nil {
			log.Fatal(err)
		}

		io.Copy(part, file)
		writer.Close()
		req, err := http.NewRequest("POST", uploadURL.String(), body)
		if err != nil {
			log.Fatal(err)
		}

		req.Header.Add("Content-Type", writer.FormDataContentType())
		req.SetBasicAuth(*user, *pass)
		res, err := client.Do(req)
		if err != nil {
			log.Fatal(err)
		}
		defer res.Body.Close()

		if res.StatusCode != http.StatusAccepted {
			log.Fatalf("unexpected response status code:%v", res.StatusCode)
		}

		jsonRes, err := ioutil.ReadAll(res.Body)
		if err != nil {
			log.Fatal(err)
		}

		fmt.Println("\nRESPONSE>>>>> " + string(jsonRes) + "\n")
	}

}
