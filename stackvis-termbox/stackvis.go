package main

import "./ui"

import (
  "os"
  "fmt"
  "io/ioutil"
)

func main() {
  if len(os.Args) != 2 {
    fmt.Printf("Usage: %v <path/to/json>\n", os.Args[0])
    os.Exit(1)
  }

  file, e := ioutil.ReadFile(filepath)
  if e != nil {
    fmt.Printf("File error: %v\n", e)
    os.Exit(1)
  }

  ui.VisualizeStack(string(file))
}
