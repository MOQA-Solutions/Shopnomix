# Shopnomix

This Application represents a Web Interface to test the Word Processor Server

## Installation & Running

```
git clone https://github.com/MOQA-Solutions/Shopnomix
cd Shopnomix
mix deps.get
iex -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Notes

- Be carreful when entering data in the form, **White Space** is considered a character
- In `Replace` session, entering `ab` and ` ` will replace any occurence of `ab` by one white space
- In `Delete` session, entered characteres should be separated by commas
  - Entering `aa, b,c` results in 3 substrings: `aa` and ` b` which is 2 chars string
    (white space + `b`) and `c`
  - Entering `a,b,c` results in 3 substrings: `a` and `b` and `c` 
  - Entering ` ` results in 1 substring: one white space which results in deleting all white spaces
  - Entering `  abc,cd  ` results in 2 substrings: ` abc`(white space + `abc`) and `cd `(`cd` + white space)
- You can set environment variables of `Processor` application in `Shopnomix/config/dev.exs`
- Once you choose any of the operations to perform on the text data in the home page, the data will be 
  loaded from the Processor Server and will be displayed
- Each update of the data by a client will result to an update on the Processor Server
- Once the data is updated, this update will be broadcasted to all connected clients 
  and the changes will be applied in realtime(**LiveView**)
- You can play around with this application by opening multi Chrome Tabs, and choose any of 
  the operations to perform, and you can see how it works perfectly in terms of concurreny.
 
