knex = require 'knex'
path = require 'path'

dbPath = path.resolve __dirname, '../data/db.sqlite'
console.log dbPath
knex = knex {client: 'sqlite3', connection: {filename: dbPath}}
bookshelf = require('bookshelf')(knex)
