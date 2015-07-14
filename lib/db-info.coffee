knex = require 'knex'
path = require 'path'
Q = require 'q'

module.exports =
class DBInfo
  constructor: (dbPath) ->
    dbPath ?= path.resolve __dirname, '../data/db.sqlite'
    this.knex = knex {client: 'sqlite3', connection: {filename: dbPath}}
    this.bookshelf = require('bookshelf')(this.knex)

  createTables: ->
    Q.all [@_createFolder(), @_createFolderChange()]

  destroyTables: ->
    Q.all [
      @knex.schema.dropTable('folders'),
      @knex.schema.dropTable('folderChanges'),
    ]

  close: (callback) ->
    @knex.destroy callback

  _createTableIfNotExists: (tableName, callback) ->
    @knex.schema.hasTable(tableName).then (exists) =>
      @knex.schema.createTable(tableName, callback) unless exists

  _createFolder: ->
    @_createTableIfNotExists 'folders', (table) ->
      table.increments('id')
      table.integer('parentId').references('folders.id')
      table.string('displayName')

  _createFolderChange: ->
    @_createTableIfNotExists 'folderChanges', (table) ->
      table.increments('id')
      table.json('changes')
