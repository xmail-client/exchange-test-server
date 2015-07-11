{knex} = require './bookshelf'

module.exports = ->
  knex.schema.dropTableIfExists('folders').then ->
    knex.schema.createTable 'folders', (table) ->
      table.increments('id')
      table.integer('parentId').references('folders.id')
      table.string('displayName')
