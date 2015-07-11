knex = require 'knex'
path = require 'path'

dbPath = path.resolve __dirname, '../data/db.sqlite'
knex = knex {client: 'sqlite3', connection: {filename: dbPath}}

exports.bookshelf = require('bookshelf')(knex)
exports.knex = knex
