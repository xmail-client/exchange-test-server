Q = require 'q'

module.exports =
class Models
  constructor: (@bookshelf) ->
    @createModels()

  createModels: ->
    Folder = @bookshelf.Model.extend
      tableName: 'folders'
      parent: ->
        this.belongsTo Folder, 'parentId'

    Folder.builtInFolders = [
      'inbox', 'drafts', 'sentitems', 'deleteditems', 'junkemail']
    Folder.insertRootInboxFolder = ->
      new Folder(displayName: 'msgfolderroot').save().then (rootFolder) ->
        promises = for name in Folder.builtInFolders
          new Folder(displayName: name, parentId: rootFolder.id).save()
        Q.all promises

    @Folder = Folder

    @FolderChange = @bookshelf.Model.extend
      tableName: 'folderChanges'
      getChanges: ->
        JSON.parse @get('changes')

  init: ->
    @Folder.insertRootInboxFolder()
