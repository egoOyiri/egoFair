class Cube
   constructor: (@projects, @states) ->

   makeGraphs: (error, projectsJson, statesJson) -> (

     #Clean projectsJson data
     donorschooseProjects = projectsJson

     dateFormat = d3.time.format("%Y-%m-%d")
     donorschooseProjects.forEach (d) ->
                d["date_posted"] = dateFormat.parse d["date_posted"]
                d["date_posted"].setDate 1
                d["total_donations"] = +d["total_donations"]

     #Create a Crossfilter instance
     ndx = crossfilter(donorschooseProjects)

     #Define Dimensions
     dateDim = ndx.dimension (d) -> d["date_posted"]
     resourceTypeDim = ndx.dimension (d) -> d["resource_type"]
     povertyLevelDim = ndx.dimension (d) -> d["poverty_level"]
     stateDim = ndx.dimension (d) -> d["school_state"]
     totalDonationsDim  = ndx.dimension (d) -> d["total_donations"]

     #Calculate metrics
     numProjectsByDate = dateDim.group()
     numProjectsByResourceType = resourceTypeDim.group()
     numProjectsByPovertyLevel = povertyLevelDim.group()
     totalDonationsByState = stateDim.group().reduceSum (d) -> d["total_donations"]
     totalDonations = ndx.groupAll().reduceSum (d) -> d["total_donations"]
     max_state = totalDonationsByState.top(1)[0].value
     all = ndx.groupAll()

     #Define values (to be used in charts)
     minDate = dateDim.bottom(1)[0]["date_posted"]
     maxDate = dateDim.top(1)[0]["date_posted"]

     #Charts
     timeChart = dc.barChart "#time-chart"
     timeChart
        .width 600
        .height 160
        .margins top: 10, right: 50, bottom: 30, left: 50
        .dimension dateDim
        .group numProjectsByDate
        .transitionDuration 500
        .x d3.time.scale().domain [minDate, maxDate]
        .elasticY true
        .xAxisLabel "Year"
        .yAxis().ticks 4

     resourceTypeChart = dc.rowChart "#resource-type-row-chart"
     resourceTypeChart
        .width 300
        .height 250
        .dimension resourceTypeDim
        .group numProjectsByResourceType
        .xAxis().ticks 4

     povertyLevelChart = dc.rowChart "#poverty-level-row-chart"
     povertyLevelChart
        .width 300
        .height 250
        .dimension povertyLevelDim
        .group numProjectsByPovertyLevel
        .xAxis().ticks 4

     numberProjectsND = dc.numberDisplay("#number-projects-nd")
     numberProjectsND
       .formatNumber d3.format "d"
       .valueAccessor (d) -> d
       .group(all)

     totalDonationsND = dc.numberDisplay("#total-donations-nd")
     totalDonationsND
       .formatNumber d3.format "d"
       .valueAccessor (d) -> d
       .group(totalDonations)
       .formatNumber d3.format ".3s"

     usChart = dc.geoChoroplethChart "#us-chart"
     usChart
        .width 1000
        .height 330
        .dimension stateDim
        .group totalDonationsByState
        .colorDomain [0, max_state]
        .colors [  "#E2F2FF"
                   "#C4E4FF"
                   "#9ED2FF"
                   "#81C5FF"
                   "#6BBAFF"
                   "#51AEFF"
                   "#36A2FF"
                   "#1E96FF"
                   "#0089FF"
                   "#0061B5" ]
         .projection (d3.geo.albersUsa().scale(600).translate [340, 150])
         .title (p) ->
              "State: " + p["key"] +
              "\n" + "Total Donations: " +
              Math.round(p["value"])  + " $"
         .overlayGeoJson statesJson["features"],
                         "state",
                         (d) -> d.properties.name

     dc.renderAll()
   )

us = new Cube("/donorschoose/projects", "static/geojson/us-states.json")

queue()
       .defer(d3.json, us.projects)
       .defer(d3.json, us.states)
       .await(us.makeGraphs)
