knex = require 'knex'
path = require 'path'

isInit = false
knexInstance = null
bookshelfInstance = null

module.exports.initKnex = (dbPath) ->
  dbPath ?= path.resolve __dirname, '../data/db.sqlite'
  knexInstance = knex {client: 'sqlite3', connection: {filename: dbPath}}
  bookshelfInstance = require('bookshelf')(knexInstance)
  isInit = true

Object.defineProperty module.exports, 'bookshelf',
  get: ->
    unless isInit then @initKnex()
    bookshelfInstance

Object.defineProperty module.exports, 'knex',
  get: ->
    unless isInit then @initKnex()
    knexInstance
