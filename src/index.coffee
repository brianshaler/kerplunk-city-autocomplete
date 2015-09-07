es = require 'event-stream'

module.exports = (System) ->

  citySearch = (keyword) ->
    return unless keyword?.toLowerCase
    createReadStream = System.getMethod 'kerplunk-place', 'createReadStream'
    return console.log 'failed to get kerplunk-place:createReadStream' unless createReadStream

    keyword = keyword.toLowerCase()
    keyword = keyword.replace /,.*$/, ''

    resultsSent = 0
    minResults = 10

    #minPopulation = 0
    if keyword.length < 2
      minPopulation = 2000000
    else if keyword.length < 3
      minPopulation = 500000
    else if keyword.length < 4
      minPopulation = 300000
    else if keyword.length < 5
      minPopulation = 50000
    else if keyword.length < 6
      minPopulation = 10000
    else
      minPopulation = 0
    obj =
      method: 'citySearch'
      keyword: keyword
    opt =
      start: keyword
      end: keyword + String.fromCharCode 255

    filterResults = es.map (data, callback) ->
      val = data.value
      obj =
        key: data.key
        name: val[0]
        region: val[1]
        country: val[2]
        lng: val[3]
        lat: val[4]
        population: val[5]
        cityId: val[6]
        timezone: val[7]
      if resultsSent > minResults or obj.population == 0
        unless obj.population > minPopulation or val?[0]?.toLowerCase() == keyword
          return callback()
      resultsSent++
      # console.log "result ##{resultsSent}: #{obj.name} - #{obj.population}"
      callback null, obj

    stream = createReadStream opt
    stream.pipe filterResults
    stream.on 'data', (data) ->
      # data.value = [name, region, country, lng, lat, population]
      #if data.value[5]
      #searchSocket.broadcast data
    stream
    filterResults

  globals:
    public:
      styles:
        'kerplunk-city-autocomplete/css/city-autocomplete.css': ['/admin/**']

  routes:
    public:
      '/city-auto-complete': 'demo'

  handlers:
    demo: 'demo'

  init: (next) ->
    searchSocket = System.getSocket 'public-city-autocomplete'
    searchSocket.on 'receive', (spark, data) ->
      if data?.keyword
        # console.log 'search!', data.keyword
        stream = citySearch data.keyword
        stream.on 'data', (obj) ->
          spark.write obj
        #startArchive()
      else
        console.log 'client said what?', data
    searchSocket.on 'connection', (spark, data) ->
      console.log 'public-city-autocomplete connection'
    next()
