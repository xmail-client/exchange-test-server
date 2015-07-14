###
 exchange-test-server
 https://github.com/liuxiong332/exchange-test-server

 Copyright (c) 2015 liuxiong
 Licensed under the MIT license.
###
EWSParser = require './ews-parser'
express = require 'express'
bodyParser = require 'body-parser'

module.exports =
class Server
  start: (config={}, callback) ->
    if config instanceof Function
      callback = config
      config = {}

    if config.dbPath
      require('./bookshelf').initKnex(config.dbPath)

    app = express('/')
    app.use(bodyParser.text(type: '*/*'))
    app.post '/EWS/Exchange.asmx', (req, res) ->
      new EWSParser().parse(req.body).then (resDoc) ->
        res.set('Content-Type', 'text/xml')
        res.send resDoc.toString()

    @server = app.listen config.port ? 3000, callback

  close: (callback) ->
    @server.close(callback) if @server
