es = require 'event-stream'
Hifo = require 'hifo-stream'

module.exports = (System) ->

  citySearch = (keyword) ->
    return unless keyword?.toLowerCase
    createReadStream = System.getMethod 'kerplunk-place', 'createReadStream'
    PlaceTransforms = System.getMethod 'kerplunk-place', 'transforms'
    return console.log 'failed to get kerplunk-place:createReadStream' unless createReadStream

    keyword = keyword.toLowerCase()
    keyword = keyword.replace /,.*$/, ''

    resultsSent = 0
    minResults = 10

    key = "nm:#{keyword}"
    opt =
      start: key
      end: key + String.fromCharCode 255

    levelToCity = es.map (data, callback) ->
      callback null, PlaceTransforms().levelToCity data.value

    sortfn = (a, b) -> b.value[5] - a.value[5]

    hifo = Hifo sortfn, 10
    createReadStream opt
    .pipe hifo.filter()
    .pipe levelToCity

  globals:
    public:
      css:
        'kerplunk-city-autocomplete:input': 'kerplunk-city-autocomplete/css/city-autocomplete.css'

  routes:
    public:
      '/city-auto-complete': 'demo'

  handlers:
    demo: 'demo'

  init: (next) ->
    searchSocket = System.getSocket 'public-city-autocomplete'
    searchSocket.on 'receive', (spark, data) ->
      if data?.keyword
        stream = citySearch data.keyword
        stream?.on 'data', (obj) ->
          spark.write obj
      else
        console.log 'client said what?', data
    searchSocket.on 'connection', (spark, data) ->
      console.log 'public-city-autocomplete connection'
    next()
