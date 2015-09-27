_ = require 'lodash'
React = require 'react'

Input = require './input'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    location: {}
    coords: [0,0]
    useCoords: true

  updateCoord: (key) ->
    (e) =>
      coords = @state.coords ? []
      coords[key] = e.target.value
      @setState
        coords: coords

  toggleCoords: (e) ->
    @setState
      useCoords: e.target.checked

  setCoordsTo: (coords) ->
    (e) =>
      e.preventDefault()
      @setState
        coords: coords

  render: ->
    @props.getComponent 'kerplunk-city-autocomplete:input'

    coords = [parseFloat(@state.coords[0]), parseFloat(@state.coords[1])]
    coords = null if isNaN(coords[0]) or isNaN(coords[1])
    coords = null if coords?[0] == 0 and coords?[1] == 0
    coords = null unless @state.useCoords
    console.log 'coords', coords
    DOM.section
      className: 'content'
    ,
      DOM.h3 null, 'City Autocomplete Demo'
      DOM.div
        className: 'row'
      ,
        DOM.div
          className: 'col col-sm-6'
        ,
          Input _.extend {}, @props,
            onChange: ->
            city: @state.location
            location: (coords if coords)
            onSelect: (city) =>
              console.log 'setting location', city
              @setState
                location: city
          if @state.location?.guid
            DOM.pre null, JSON.stringify @state.location, null, 2
        DOM.div
          className: 'col col-sm-6'
        ,
          DOM.p null,
            DOM.input
              type: 'checkbox'
              id: 'useCoords'
              onChange: @toggleCoords
              checked: @state.useCoords
            ' '
            DOM.label
              htmlFor: 'useCoords'
            ,
             'use coordinates'
             if coords
               " (#{coords[0]}, #{coords[1]})"
          DOM.p null,
            DOM.h4 null, 'longitude'
            DOM.input
              onChange: @updateCoord 0
              placeholder: 'longitude'
              value: @state.coords[0]
          DOM.p null,
            DOM.h4 null, 'latitude'
            DOM.input
              onChange: @updateCoord 1
              placeholder: 'latitude'
              value: @state.coords[1]
          DOM.p null,
            DOM.a
              href: '#'
              onClick: @setCoordsTo [13.4, 52.5]
            , 'Set to Berlin'
          DOM.p null,
            DOM.a
              href: '#'
              onClick: @setCoordsTo [-112.1, 33.4]
            , 'Set to Phoenix'
          DOM.p null,
            DOM.a
              href: '#'
              onClick: @setCoordsTo [-75.2, 40]
            , 'Set to Philadelphia'
