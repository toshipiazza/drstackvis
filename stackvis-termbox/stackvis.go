package main

import (
  termboxutil "github.com/hoffoo/termboxutil"
  termbox "github.com/nsf/termbox-go"
  stackutils "./stackutils"
  "encoding/json"
  "io/ioutil"
  "fmt"
  "os"
)


func parseJSON(filepath string) (w []stackutils.Write) {
  file, e := ioutil.ReadFile(filepath)
  if e != nil {
    fmt.Printf("File error: %v\n", e)
    os.Exit(1)
  }
  json.Unmarshal(file, &w)
  return
}


func eventLoop(w []stackutils.Write) {
  tick := 0
  stack := stackutils.CreateStack(w)

  // termbox init
  if err := termbox.Init(); err != nil {
    panic(err)
  }
  defer termbox.Close()
  termbox.SetCursor(-1,-1)

  // termboxutil init
  screen := termboxutil.Screen { }
  stackWindow := screen.NewWindow(
    termbox.ColorWhite,
    termbox.ColorDefault,
    termbox.ColorGreen,
    termbox.ColorBlack)
  stackWindow.Scrollable(true)
  err := stackWindow.Draw(stack.CreateStackString(tick))
  screen.Focus(&stackWindow)
  if err != nil {
    panic(err)
  }

  stackWindow.CatchEvent = func (event termbox.Event) {
    if event.Ch == 'j' || event.Key == termbox.KeyArrowDown {
      stackWindow.NextRow()
    } else if event.Ch == 'k' || event.Key == termbox.KeyArrowUp {
      stackWindow.PrevRow()
    } else if event.Ch == 'h' || event.Key == termbox.KeyArrowRight {
      if tick != 0 {
        tick -= 1
        err := stackWindow.Draw(stack.CreateStackString(tick))
        if err != nil {
          panic(err)
        }
      }
    } else if event.Ch == 'l' || event.Key == termbox.KeyArrowLeft {
      // TODO: check bounds on tick
      tick += 1
      err := stackWindow.Draw(stack.CreateStackString(tick))
      if err != nil {
        panic(err)
      }
    } else if event.Ch == 'q' || event.Key == termbox.KeyEsc {
      termbox.Close()
      os.Exit(0)
    }

    stackWindow.Redraw()
    termbox.Flush()
  }

  termbox.Flush()
  screen.Loop()
}


func main() {
  if len(os.Args) != 2 {
    fmt.Println("Usage: %v <path/to/json>", os.Args[0])
    os.Exit(1)
  }

  // load json
  fmt.Print("Reading in json... ")
  w := parseJSON(os.Args[1])
  fmt.Printf("done! Read %v writes\n", len(w))

  // run the event loop
  eventLoop(w)
}
