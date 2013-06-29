This is written in literate coffeescript!

First we define some global variables. `map` is the Google map object we will create shortly. We define a starting point for our map, which is currently set to Shibuya, Tokyo, Japan. The maxTime is the longest amount of time, in minutes, we are going to show the user where she can go.
    
    map = undefined
    startingPoint = new google.maps.LatLng(35.658482, 139.651376)
    maxTime = 30

`circleDrawing` is where we will store the final array of paths that are to be cut out of the `everythingElse` earth-covering polygon. We will have to do a union of all the circles we want to draw to make it look right, but more on that later.

    circleDrawing = null
    circles = []
    pointsOfInterest = []
    bounds = null

We need a polygon to cover the entire service of the earth, so that we can cut holes into that to show where the user is able to go within a certain amount of time. To this end, we define a triangle that stretches from latitude -87 to the 3 corners of the Google Maps earth. Interestingly, using a rectangle here simply results in a line that runs from North to South along the 180° line!

    everythingElse = [
      new google.maps.LatLng(-87, 120), 
      new google.maps.LatLng(-87, -87), 
      new google.maps.LatLng(-87, 0)
    ]

    class PointOfInterest
      constructor: (@latLng) ->
        @bucket = ([] for num in [0..31])

      addPoint: (mins, lat, lng) ->
        mins = parseInt(Math.min(31, mins))
        @bucket[mins].push
          mins: mins
          point: new google.maps.LatLng(lat, lng)

      getUpTo: (mins) ->
        console.log @bucket[0..mins]
        return [].concat @bucket[0..mins]...

    class Circle
      constructor: (@center, @radius, @points) ->

      getPath: () ->
        point = @center
        radius = @radius
        points = @points
        dir = -1

        d2r = Math.PI / 180 # degrees to radians
        r2d = 180 / Math.PI # radians to degrees
        earthsradius = 6371*1000 # 6,371 is the radius of the earth in km
        
        # find the raidus in lat/lon 
        rlat = (radius / earthsradius) * r2d
        rlng = rlat / Math.cos(point.lat() * d2r)
        extp = new Array()
        if dir is 1
          start = 0
          end = points + 1
        else
          start = points + 1
          end = 0
        i = start

        while ((if dir is 1 then i < end else i > end))
          theta = Math.PI * (i / (points / 2))
          ey = point.lng() + (rlng * Math.cos(theta)) # center a + radius x * cos(theta)
          ex = point.lat() + (rlat * Math.sin(theta)) # center b + radius y * sin(theta)
          extp.push new google.maps.LatLng(ex, ey)
          bounds.extend extp[extp.length - 1]
          i = i + dir
        extp





    initialize = ->
      bounds = new google.maps.LatLngBounds()

      myOptions =
        zoom: 14
        center: startingPoint
        mapTypeId: google.maps.MapTypeId.ROADMAP

      map = new google.maps.Map(document.getElementById("map_canvas"), myOptions)

      shibuya = new PointOfInterest startingPoint
      for point in window.points
        shibuya.addPoint point[0], point[1], point[2]

      pointsOfInterest.push shibuya

      #calculateDistances window.points2, "#0000FF"

    mergeCircles = (circles) ->
      newPaths = []
      for circle in circles
        # (R0-R1)^2 <= (x0-x1)^2+(y0-y1)^2 <= (R0+R1)^2
        console.log 'hes'

    window.showUpTo = (minutes) ->
      if circleDrawing
        circleDrawing.setMap(null)
      circles = []

      for pointOfInterest in pointsOfInterest
        for point in pointOfInterest.getUpTo(minutes)
          # humans walk about 83 meters per minute
          circles.push new Circle(point.point, (minutes + 1 - point.mins) * 83, 16)

      mergeCircles(circles)
      circles = (c.getPath() for c in circles)
      # draw
      circles.unshift everythingElse
      circleDrawing = new google.maps.Polygon({
        paths: circles,
        strokeColor: '#000000',
        strokeOpacity: 0,
        strokeWeight: 0,
        fillColor: '#FF0000',
        fillOpacity: 0.35
      });
      circleDrawing.setMap(map);


    calculateDistances = (points, color) ->
      i = 0

      while i < points.length
        dest = points[i]
        latlng = new google.maps.LatLng(dest[1], dest[2])
        DrawCircle map, latlng, 50 * (maxTime + 1 - dest[0]), color  if dest[0] <= maxTime
        i++

    $ ()->
        initialize()
