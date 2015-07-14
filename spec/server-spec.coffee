Server = require '../lib/server'
Request = require './request-helper'
http = require 'http'

describe 'start server', ->
  server = null
  beforeEach (done) ->
    server = new Server
    server.start done

  afterEach (done) ->
    server.close done

  it 'can response', (done) ->
    config =
      port: 3000, method: 'POST', path: '/EWS/Exchange.asmx'
      headers:
        'Content-Type': 'application/xml'

    req = http.request config, (res) ->
      done()
    req.end new Request.GetFolderRequest().build('inbox').toString()
