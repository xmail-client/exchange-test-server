assert = require 'should'
DBInfo = require '../lib/db-info'
Models = require '../lib/models'

describe 'Folder class', ->
  [dbInfo, models] = []
  beforeEach (done) ->
    dbInfo = new DBInfo()
    dbInfo.createTables().then ->
      models = new Models(dbInfo.bookshelf)
      models.init()
    .then -> done()
    .catch done

  afterEach (done) ->
    dbInfo.destroyTables().then ->  dbInfo.close done

  it 'insert the root and inbox foldera', (done) ->
    new models.Folder(id: 2).fetch(withRelated: ['parent']).then (folder) ->
      folder.get('displayName').should.equal 'inbox'
      folder.related('parent').get('displayName').should.equal 'msgfolderroot'
      done()
    .catch done
