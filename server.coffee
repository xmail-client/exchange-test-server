###
 exchange-test-server
 https://github.com/liuxiong332/exchange-test-server

 Copyright (c) 2015 liuxiong
 Licensed under the MIT license.
###

express = require 'express'
app = express('/')

app.post '/EWS/Exchange.asmx', (req, res) ->
  res.send 'Hello World'

server = app.listen 3000, ->
  port = server.address().port
  console.log "app listening at http://localhost:#{port}"
