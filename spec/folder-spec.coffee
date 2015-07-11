schema = require '../lib/schema-generator'
{knex} = require '../lib/bookshelf'
Folder = require '../lib/folder'
assert = require 'should'

describe 'Folder class', ->
  beforeEach (done) ->
    schema().then ->
      Folder.insertRootInboxFolder()
    .then -> done()
    .catch done

  afterEach (done) ->
    knex.destroy(done)

  it 'insert the root and inbox foldera', (done) ->
    new Folder(id: 2).fetch(withRelated: ['parent']).then (folder) ->
      folder.get('displayName').should.equal 'inbox'
      folder.related('parent').get('displayName').should.equal 'msgfolderroot'
      done()
    .catch done
