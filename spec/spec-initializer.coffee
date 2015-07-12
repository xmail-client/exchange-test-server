Q = require 'q'
schema = require '../lib/schema-generator'
{knex} = require '../lib/bookshelf'
Folder = require '../lib/folder'

beforeEach (done) ->
  schema().then ->
    Folder.insertRootInboxFolder()
  .then -> done()
  .catch done

afterEach (done) ->
  Q.all [
    knex.schema.dropTable('folders'),
    knex.schema.dropTable('folderChanges'),
  ]
  .then -> done()
  .catch done

after (done) ->
  knex.destroy(done)
