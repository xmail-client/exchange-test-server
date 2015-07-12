schema = require '../lib/schema-generator'
{knex} = require '../lib/bookshelf'
Folder = require '../lib/folder'

beforeEach (done) ->
  schema().then ->
    Folder.insertRootInboxFolder()
  .then -> done()
  .catch done

after (done) ->
  knex.destroy(done)
