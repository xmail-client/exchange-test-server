
module.exports =
class Models
  constructor: (@bookshelf) ->
    @createModels()

  createModels: ->
    Folder = @bookshelf.Model.extend
      tableName: 'folders'
      parent: ->
        this.belongsTo Folder, 'parentId'

    Folder.insertRootInboxFolder = ->
      new Folder(displayName: 'msgfolderroot').save().then (rootFolder) ->
        new Folder(displayName: 'inbox', parentId: rootFolder.id).save()

    @Folder = Folder

    @FolderChange = @bookshelf.Model.extend
      tableName: 'folderChanges'
      getChanges: ->
        JSON.parse @get('changes')

  init: ->
    @Folder.insertRootInboxFolder()
