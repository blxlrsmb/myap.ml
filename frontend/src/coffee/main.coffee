$ ->
  server = 'http://api.myap.ml'
  # id = location.search.match(/[^=]+$/)[0]
  width = Math.min window.innerWidth, 1280

  match = location.search.match /[^=]+$/
  if match
    id = match[0]
  else
    id = 233

  d3.json "#{server}/summary/#{id}", (err, data) ->
    origin = data
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
    #stacked
    (->
      stack = `
        function(data) {
          var startPoints = [];
          var endPoints = [];
          var apps = [];
          for (var key in data.data) {
            apps.push(key);
            for (var i = 0; i < data.data[key].length; ++i) {
              startPoints.push(data.data[key][i].start);
              endPoints.push(data.data[key][i].end);
            }
          }
          var appKeyIndex = {};
          for (var i = 0; i < apps.length; ++i) {
            appKeyIndex[apps[i]] = i;
          }
          var globalStartTime = Math.min.apply(null, startPoints);
          var globalEndTime = Math.max.apply(null, endPoints);
          var duration = globalEndTime - globalStartTime;
          var bucketSize = Math.ceil(duration / 10);
          var interval = 5;
          var layers = [];
          for (var app in data.data) {
            layers[appKeyIndex[app]] = [];
            for (var i = 0; i < 10; ++i) {
              layers[appKeyIndex[app]][i] = {
                x: i,
                y: 0.1,
                y0: 0
              };
            }
            for (var i = 0; i < data.data[app].length; ++i) {
              var eventBatch = data.data[app][i];
              for (var j = 0; j < eventBatch.count.length; ++j) {
                var bucket = Math.floor((j * interval + eventBatch.start.getTime() - globalStartTime) / bucketSize);
                console.log(bucket);
                layers[appKeyIndex[app]][bucket].y += eventBatch.count[j];
              }
            }
          }
          console.dir(layers);

        var n = 6, // number of layers
            m = 10, // number of samples per layer
            stack = d3.layout.stack(),
            // layers = stack(d3.range(n).map(function() { return bumpLayer(m, .1); })),
            yGroupMax = d3.max(layers, function(layer) { return d3.max(layer, function(d) { return d.y; }); }),
            yStackMax = d3.max(layers, function(layer) { return d3.max(layer, function(d) { return d.y0 + d.y; }); });

        console.dir(layers);

        var height = 200;

        var x = d3.scale.ordinal()
            .domain(d3.range(m))
            .rangeRoundBands([0, width], .08);

        var y = d3.scale.linear()
            .domain([0, yStackMax])
            .range([height, 0]);

        var color = d3.scale.linear()
            .domain([0, n - 1])
            .range(["#aad", "#556"]);

        var xAxis = d3.svg.axis()
            .scale(x)
            .tickSize(0)
            .tickPadding(6)
            .orient("bottom");

        var svg = d3.select("#stacked").append("svg")
            .attr("width", width)
            .attr("height", height)
            .append("g");

        var layer = svg.selectAll(".layer")
            .data(layers)
            .enter().append("g")
            .attr("class", "layer")
            .style("fill", function(d, i) { return color(i); });

        var rect = layer.selectAll("rect")
            .data(function(d) { return d; })
            .enter().append("rect")
            .attr("x", function(d) { return x(d.x); })
            .attr("y", height)
            .attr("width", x.rangeBand())
            .attr("height", 0);

        rect.transition()
            .delay(function(d, i) { return i * 10; })
            .attr("y", function(d) { return y(d.y0 + d.y); })
            .attr("height", function(d) { return y(d.y0) - y(d.y0 + d.y); });

        svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis);

        d3.selectAll("input").on("change", change);

        var timeout = setTimeout(function() {
          d3.select("input[value=\"grouped\"]").property("checked", true).each(change);
        }, 2000);

        function change() {
          clearTimeout(timeout);
          if (this.value === "grouped") transitionGrouped();
          else transitionStacked();
        }

        function transitionGrouped() {
          y.domain([0, yGroupMax]);

          rect.transition()
              .duration(500)
              .delay(function(d, i) { return i * 10; })
              .attr("x", function(d, i, j) { return x(d.x) + x.rangeBand() / n * j; })
              .attr("width", x.rangeBand() / n)
            .transition()
              .attr("y", function(d) { return y(d.y); })
              .attr("height", function(d) { return height - y(d.y); });
        }

        function transitionStacked() {
          y.domain([0, yStackMax]);

          rect.transition()
              .duration(500)
              .delay(function(d, i) { return i * 10; })
              .attr("y", function(d) { return y(d.y0 + d.y); })
              .attr("height", function(d) { return y(d.y0) - y(d.y0 + d.y); })
            .transition()
              .attr("x", function(d) { return x(d.x); })
              .attr("width", x.rangeBand());
        }

        // Inspired by Lee Byron's test data generator.
        function bumpLayer(n, o) {

          function bump(a) {
            var x = 1 / (.1 + Math.random()),
                y = 2 * Math.random() - .5,
                z = 10 / (.1 + Math.random());
            for (var i = 0; i < n; i++) {
              var w = (i / n - y) * z;
              a[i] += x * Math.exp(-w * w);
            }
          }

          var a = [], i;
          for (i = 0; i < n; ++i) a[i] = o + o * Math.random();
          for (i = 0; i < 5; ++i) bump(a);
          return a.map(function(d, i) { return {x: i, y: Math.max(0, d)}; });
        }

        };
      `
      console.log origin
      stack origin
    )()
