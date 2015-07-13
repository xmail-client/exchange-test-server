###
 exchange-test-server
 https://github.com/liuxiong332/exchange-test-server

 Copyright (c) 2015 liuxiong
 Licensed under the MIT license.
###
EWSParser = require './ews-parser'
express = require 'express'

module.exports = (port=3000, callback) ->
  if port instanceof Function
    port = 3000
    callback = port

  app = express('/')
  app.post '/EWS/Exchange.asmx', (req, res) ->
    EWSParser.parse(req.body).then (resDoc) ->
      res.set('Content-Type', 'application/xml')
      res.send resDoc.toString()

  server = app.listen port, callback
