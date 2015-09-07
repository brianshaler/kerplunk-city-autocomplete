_ = require 'lodash'
React = require 'react'

Input = require './input'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    location: {}

  render: ->
    DOM.section
      className: 'content'
    ,
      DOM.h3 null, 'City Autocomplete Demo'
      Input _.extend {}, @props,
        onChange: ->
        city: @state.location
        location: @state.location?.location
        onSelect: (city) =>
          console.log 'setting location', city
          @setState
            location: city
      if @state.location?.location
        DOM.pre null, JSON.stringify @state.location, null, 2
