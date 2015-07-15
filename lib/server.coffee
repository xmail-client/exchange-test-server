###
 exchange-test-server
 https://github.com/liuxiong332/exchange-test-server

 Copyright (c) 2015 liuxiong
 Licensed under the MIT license.
###
express = require 'express'
bodyParser = require 'body-parser'
Q = require 'q'
DBInfo = require('./db-info')
Models = require './models'

module.exports =
class Server
  start: (config={}, callback) ->
    if config instanceof Function
      callback = config
      config = {}

    this.dbInfo = new DBInfo(config.dbPath)

    app = express('/')
    app.use(bodyParser.text(type: '*/*'))
    app.post '/EWS/Exchange.asmx', (req, res) =>
      EWSParser = require './ews-parser'
      new EWSParser(@models).parse(req.body).then (resDoc) ->
        res.set('Content-Type', 'text/xml')
        res.send resDoc.toString(false)

    this.dbInfo.createTables().then =>
      @models = new Models(@dbInfo.bookshelf)
      @models.init()
    .then =>
      @server = app.listen config.port ? 3000, callback

  close: (callback) ->
    @dbInfo.close =>
      @server.close(callback) if @server
