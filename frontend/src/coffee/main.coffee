$ ->
  server = 'http://api.myap.ml'
  jsonPath = 'summary'
  width = Math.min window.innerWidth, 1280

  d3.json "#{server}/summary", (err, data) ->
    data = $.map data.data, (d, k) ->
      s = {}
      s.category = k
      s.periods = d.map (p) ->
        p.start = new Date p.start
        p.end = new Date p.end
        p
      s.open = new Date Math.min.apply null, d.map (p) -> p.start
      s.close = new Date Math.max.apply null, d.map (p) -> p.end
      s.total = d.reduce (prev, curr) ->
          curr.count.reduce((prev, curr) ->
            prev + curr
          , 0) + prev
        ,0
      s.time = d.reduce (prev, curr) ->
          (curr.end - curr.start) + prev
        , 0
      s
    data.sort (a, b) ->
      b.total - a.total
    l = data.length
    colors = randomColor count: l, hue: 'random', luminosity: 'light'

    #total
    (->
      svg = d3.select '#total'
        .append 'svg'
        .attr 'width', width
        .append 'g'

      height = 30 * l

      x = d3.scale.linear().range [0, width]
        .domain [0, d3.max data.map (d) -> d.total]
      y = d3.scale.ordinal().rangeRoundBands [0, height], 0.01
        .domain data.map (d) -> d.category

      svg.selectAll '.bar'
        .data data
        .enter()
        .append 'g'
        .attr 'class', 'bar'

      svg.selectAll '.bar'
        .append 'rect'
        .attr 'class', 'rect'
        .attr 'y', (d) -> y d.category
        .attr 'height', y.rangeBand()
        .attr 'x', 0
        .attr 'width', (d) ->
          x(d.total) / 2
        .attr 'fill', (d) ->
          colors[data.indexOf d]

      svg.selectAll '.bar'
        .append 'text'
        .text (d) -> "#{d.total}(#{(d.total / d.time).toFixed 2}/s) #{d.category}"
        .attr 'class', 'text'
        .attr 'y', (d) ->  y.rangeBand() / 2 + y d.category
        .attr 'x', (d) ->
          x(d.total) / 2 + 10
    )()

    #frequency
    (->
      svg = d3.select '#frequency'
        .append 'svg'
        .append 'g'

      earliest = Math.min.apply null, data.map (d) -> d.open
      last = Math.max.apply null, data.map (d) -> d.close

      count = {}
      for d in data
        for p in d.periods
          for ci in [0 .. p.count.length - 1]
            count[p.start.getTime() + ci * 5] ?= 0
            count[p.start.getTime() + ci * 5] += p.count[ci]
      count = $.map count, (v, i) ->
        date: parseInt(i), count: v
      count.sort (a, b) ->
        a.date - b.date
      height = 100

      x = d3.scale.linear().range [0, width]
        .domain [earliest, last]
      y = d3.scale.linear().range [height, 0]
        .domain [0, d3.max count.map (d) -> d.count]
      line = d3.svg.line()
        .x (d) -> x d.date
        .y (d) -> y d.count
      svg.append 'path'
        .datum count
        .attr 'class', 'line'
        .attr 'd', line
        .attr 'fill', 'none'
        .attr 'stroke', 'blue'
    )()
    #pie
    (->
      height = 300
      pie = d3.layout.pie()
        .sort (a, b) ->
          b.time - a.time
        .value (d) -> d.time
      sdata = pie data
      console.log sdata
      svg = d3.select '#pie'
        .append 'svg'
        .attr 'width', width
        .attr 'height', height
        .append 'g'
        .attr 'transform', "translate(#{width / 2}, #{height / 2})"
      arc = d3.svg.arc()
        .outerRadius height / 2
        .innerRadius height / 6
      g = svg.selectAll '.arc'
        .data sdata
        .enter()
        .append 'g'
        .attr 'class', 'arc'
      g.append 'path'
        .attr 'd', arc
        .style 'fill', (d) ->
          colors[sdata.indexOf d]
      g.append 'text'
        .attr 'transform', (d) -> "translate(#{arc.centroid d})"
        .attr 'dy', '.35em'
        .style 'text-anchor', 'middle'
        .text (d) -> d.data.category
    )()
