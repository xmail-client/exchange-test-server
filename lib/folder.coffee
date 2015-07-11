{bookshelf} = require './bookshelf'

module.exports =
Folder = bookshelf.Model.extend
  tableName: 'folders'

  parent: ->
    this.belongsTo Folder, 'parentId'

Folder.insertRootInboxFolder = ->
  new Folder(displayName: 'msgfolderroot').save().then (rootFolder) ->
    new Folder(displayName: 'inbox', parentId: rootFolder.id).save()

Folder.get = (id) ->
  new Folder(id: id).fetch()

Folder.getByDisplayName = (name) ->
  new Folder(displayName: name).fetch()
