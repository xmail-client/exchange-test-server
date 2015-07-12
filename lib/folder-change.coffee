{bookshelf} = require './bookshelf'

module.exports =
FolderChange = bookshelf.Model.extend
  tableName: 'folderChanges'

  getChanges: ->
    JSON.parse @get('changes')
