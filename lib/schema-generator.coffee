{knex} = require './bookshelf'
Q = require 'q'

createTableIfNotExists = (tableName, callback) ->
  knex.schema.hasTable(tableName).then (exists) ->
    knex.schema.createTable(tableName, callback) unless exists

createFolder = ->
  createTableIfNotExists 'folders', (table) ->
    table.increments('id')
    table.integer('parentId').references('folders.id')
    table.string('displayName')

createFolderChange = ->
  createTableIfNotExists 'folderChanges', (table) ->
    table.increments('id')
    table.json('changes')

module.exports = ->
  Q.all [createFolder(), createFolderChange()]
