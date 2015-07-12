schema = require '../lib/schema-generator'
{knex} = require '../lib/bookshelf'
Folder = require '../lib/folder'
assert = require 'should'

describe 'Folder class', ->

  it 'insert the root and inbox foldera', (done) ->
    new Folder(id: 2).fetch(withRelated: ['parent']).then (folder) ->
      folder.get('displayName').should.equal 'inbox'
      folder.related('parent').get('displayName').should.equal 'msgfolderroot'
      done()
    .catch done
