
exchangeTestServer = require '../lib/exchange-test-server'

assert = require 'should' 

describe 'exchangeTestServer', ->

  it 'should be awesome', -> 
    exchangeTestServer().should.equal('awesome')
