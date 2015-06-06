crypto = require 'crypto'
xml2js = require 'xml2js'
Q = require 'q'
utils = require '../utils'
database = require '../database'

logger = utils.logging.newConsoleLogger module.filename

redisConnection = database.getConnection()

authenticationHandler = (req, res, next) ->
  token = 'EastIndiaCompany'
  timestamp = req.query['timestamp']
  nonce = req.query['nonce']
  signature = req.query['signature']
  echostr = req.query['echostr']
  l = [token, timestamp, nonce].sort().join ''
  shasum = crypto.createHash 'sha1'
  shasum.update l
  res.contentType = 'text'
  if shasum.digest('hex') == signature
    logger.debug 'authentication success'
    res.send 200, echostr
  else
    logger.debug 'authentication failed'
    res.send 200

echoHandler = (req, res, next) ->
  logger.debug "request body #{req.body}"
  Q.ninvoke xml2js, 'parseString', req.body
  .then (parsed) ->
    toUser = parsed.xml['FromUserName'][0]
    fromUser = parsed.xml['ToUserName'][0]
    createTime = (new Date()).getTime() // 1000
    content = "echo #{parsed.xml['Content'][0]}"
    ret = "
      <xml>
        <ToUserName><![CDATA[#{toUser}]]></ToUserName>
        <FromUserName><![CDATA[#{fromUser}]]></FromUserName>
        <CreateTime>#{createTime}</CreateTime>
        <MsgType><![CDATA[text]]></MsgType>
        <Content><![CDATA[#{content}]]></Content>
      </xml>"
    res.contentType = 'text'
    res.send 200, ret
    next()
  .done()

rpcCall = (tag, payload, sendResponse) ->
  if tag == 'echo'
    sendResponse "echo #{payload.request}"
  else if tag == 'login'
    if payload.request.match /[^0-9a-z]/i
      sendResponse 'only letters and digits allowed'
    else
      Q.ninvoke redisConnection, 'hset', 'login', payload.fromUser, payload.request
      sendResponse 'OK'
  else if tag == 'summary'
    Q.ninvoke redisConnection, 'hget', 'login', payload.fromUser
    .then (id) ->
      logger.debug id
      if not id
        sendResponse 'please login first'
      else
        sendResponse "http://myap.ml/?id=#{id}"
    .done()
  else
    sendResponse "invalid tag #{tag}"

rpcHandler = (req, res, next) ->
  console.dir req.body
  Q.ninvoke xml2js, 'parseString', req.body
  .then (parsed) ->
    fromUser = parsed.xml['FromUserName'][0]
    toUser = parsed.xml['ToUserName'][0]
    createTime = (new Date()).getTime() // 1000
    sendResponse = (content) ->
      ret = "
        <xml>
          <ToUserName><![CDATA[#{fromUser}]]></ToUserName>
          <FromUserName><![CDATA[#{toUser}]]></FromUserName>
          <CreateTime>#{createTime}</CreateTime>
          <MsgType><![CDATA[text]]></MsgType>
          <Content><![CDATA[#{content}]]></Content>
        </xml>"
      res.send 200, ret
      next()
    content = parsed.xml['Content'][0]
    separatorIndex = content.indexOf ' '
    if separatorIndex == 0
      sendResponse 'invalid request'
    else
      if separatorIndex == -1
        separatorIndex = content.length
      tag = content[..separatorIndex - 1]
      request = content[separatorIndex + 1..]
      payload =
        toUser: toUser
        fromUser: fromUser
        createTime: createTime
        request: request
      rpcCall tag, payload, sendResponse
  .done()

exports.authenticationHandler = authenticationHandler
exports.echoHandler = echoHandler
exports.rpcHandler = rpcHandler

