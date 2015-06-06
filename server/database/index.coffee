redis = require 'redis'
utils = require '../utils'

logger = utils.logging.newConsoleLogger module.filename

connectionPool = {}

getConnection = (db) ->
  db ?= 0
  if not connectionPool[db]
    connection = redis.createClient
      parser: 'hiredis'
    if db != 0
      Q.ninvoke connection, 'select', db
    connectionPool[db] = connection
    logger.debug "redis connection to #{db} established"
    connection
  else
    connectionPool[db]

closeAll = ->
  logger.debug 'closing all redis connections'
  for k, v of connectionPool
    v.quit()
    delete connectionPool[k]
  return

exports.getConnection = getConnection
exports.closeAll = closeAll

