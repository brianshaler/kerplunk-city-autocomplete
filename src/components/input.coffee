_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  getDefaultProps: ->
    onChange: ->
    onSelect: ->

  getInitialState: ->
    currentVal = if @props.city
      @formatCity @props.city
    else
      ''
    active: false
    currentVal: currentVal
    results: []
    city: @props.city ? {}
    selectedCityKey: ''

  componentDidMount: ->
    window.autocompleteComponent = @
    @history = {}
    @cache = []
    @socket = @props.getSocket 'public-city-autocomplete'
    @socket.on 'data', (data) =>
      # console.log 'data', data
      return console.log 'stahp' unless @isMounted()
      exists = _.find @cache, (item) ->
        item.guid == data.guid
      @cache.push data unless exists
      @updateResults()

  componentWillUnmount: ->
    @socket.off 'data'

  componentWillReceiveProps: (newProps) ->
    if newProps.city
      formatted = @formatCity newProps.city
      @setState
        city: newProps.city
        currentVal: formatted
    true

  formatCity: (city) ->
    {name, region, country, population} = city
    segments = [name]
    if region?.length > 0
      segments.push region
    unless /united states/i.test country
      segments.push country
    # segments.push population
    segments = _.compact segments
    return '' unless segments.length > 0
    segments.join ', '

  updateResults: (currentVal = @state.currentVal) ->
    val = currentVal.toLowerCase()
    pattern = /\b([a-zA-Z]+)\b/g
    words = []
    patterns = []
    while match = pattern.exec val
      words.push match[1]
      patterns.push new RegExp "\\b#{match[1]}", 'i'
    results = _ @cache
      # .filter (item) ->
      #   item.population > minPopulation
      .filter (item) ->
        fullname = [
          item.name
          item.region
          item.country
        ].join(', ').toLowerCase()
        for pattern in patterns
          return false unless pattern.test fullname
        words.length > 0 and words[0].length > 0
      .sortBy (item) =>
        if @props.location?.length == 2
          itemLng = item.lng ? item.location?[0]
          itemLat = item.lat ? item.location?[1]
          lng = Math.abs itemLng - @props.location[0]
          lat = Math.abs itemLat - @props.location[1]
          -item.population * 0.01 + 1000 * (10 + Math.sqrt lng * lng + lat * lat)
        else
          -item.population
      # .map (item) ->
      #   "#{item.name}, #{item.region}, #{item.country} (#{item.population})"
      .value()
      .slice 0, 10

    @setState
      results: results
      currentVal: currentVal

  onChange: (e) ->
    keyword = e.target.value
    _keyword = keyword?.toLowerCase()

    if _keyword?.replace?(/[^a-z]/gi,'').length > 0 and !@history[_keyword]
      @socket.write
        keyword: _keyword
      @history[_keyword] = true

    @updateResults keyword

  onFocus: (e) ->
    el = e.target
    setTimeout ->
      el.selectionStart = 0
      el.selectionEnd = el.value.length
    , 1
    @updateResults e.target.value
    @setState
      active: true
      currentVal: e.target.value

  onBlur: ->
    setTimeout =>
      return unless @isMounted()
      @setState
        active: false
        currentVal: @formatCity @state.city
    , 100

  selectCity: (city) ->
    (e) =>
      e.preventDefault()
      console.log 'select city!', city
      @props.onSelect city

  selectByKey: (guid) ->
    city = _.find @cache, (city) ->
      city.guid == guid
    if city
      @props.onSelect city
      @setState
        currentVal: @formatCity city

  onKeyPress: (e) ->
    TAB = 9
    ENTER = 13
    UP = 38
    DOWN = 40
    if e.keyCode == UP or e.keyCode == DOWN
      dir = if e.keyCode == UP then -1 else 1

      e.preventDefault()
      console.log 'shhh', @state.selectedCityKey
      index = _.findIndex @state.results, (city) =>
        city.guid == @state.selectedCityKey
      if !index? or index == -1
        @setState
          selectedCityKey: if dir == 1
            @state.results[0]?.guid
          else
            @state.results[@state.results?.length - 1]?.guid
        return
      index += dir
      if @state.results[index]?.guid
        @setState
          selectedCityKey: @state.results[index].guid
      return
    if e.keyCode == ENTER or e.keyCode == TAB
      e.preventDefault()
      @selectByKey @state.selectedCityKey

  render: ->
    exactMatch = =>
      _.find @state.results, (city) =>
        @state.currentVal == @formatCity city

    DOM.div
      className: 'city-autocomplete'
    ,
      DOM.input
        value: @state.currentVal
        placeholder: 'autocomplete'
        onChange: @onChange
        onFocus: @onFocus
        onBlur: @onBlur
        onKeyDown: @onKeyPress
      if @state.active and @state.results.length > 0 and !exactMatch()
        DOM.div
          className: 'city-autocomplete-results'
        ,
          _.map @state.results, (city) =>
            DOM.a
              key: city.guid
              href: '#'
              onClick: @selectCity city
              className: if @state.selectedCityKey == city.guid
                'city-selected'
              else
                ''
            , @formatCity city
      else
        null
