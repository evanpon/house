$ ->
  $.ajaxSetup({
    dataType: 'json'
  })
  
  fixedImages = {}
  
  $("a[data-image-id]").hover (e) ->
    e.preventDefault()
    showImage(this)

  $("a[data-map-home-id]").hover (e) ->
    e.preventDefault()
    showMap(this)

  $("a[data-home-id]").click (e) ->
    e.preventDefault()
    homeId = $(this).data("home-id")
    imageId = $(this).data("image-id")
    frozen = fixedImages[homeId]
    setLinksToBlue(homeId)
    if frozen == imageId
      fixedImages[homeId] = null
    else
      fixedImages[homeId] = imageId 
      $(this).css('color', 'red')     

    showImage(this)
      
  $("a[data-map-home-id]").click (e) ->
    e.preventDefault()
    homeId = $(this).data("map-home-id")
    frozen = fixedImages[homeId]
    setLinksToBlue(homeId)
    if frozen == "map"
      fixedImages[homeId] = null
    else
      fixedImages[homeId] = 'map'
      $(this).css('color', 'red')
    showMap(this)


  $("form").on("ajax:success", (e, data, status, xhr) ->
    element = $(this).find(".success")
    element.show().fadeOut(1500)
    $("#score_#{data['id']}").text(data["score"])
    $("#value_#{data['id']}").text(data["value"])
  ).on "ajax:error", (e, xhr, status, error) ->
    element = $(this).find(".failure")
    element.show().fadeOut(2000)
  
  showImage = (obj) ->
    imageId = $(obj).data("image-id")
    homeId = $(obj).data("home-id")
    if !fixedImages[homeId] || fixedImages[homeId] == imageId 
      url = "https://s3-us-west-2.amazonaws.com/evanpon.applications/house/#{homeId}/#{imageId}"
      $("#image_#{homeId}").attr("src", url)
      $("#image_#{homeId}").show()
      $("#map_#{homeId}").hide()
    
  showMap = (obj) ->
    homeId = $(obj).data("map-home-id")
    if !fixedImages[homeId] || fixedImages[homeId] == 'map'
      $("#image_#{homeId}").hide()
      $("#map_#{homeId}").show()
    
  setLinksToBlue = (homeId) ->
    $("div#home_#{homeId} a[data-home-id]").css('color', 'blue')
    $("div#home_#{homeId} a[data-map-home-id]").css('color', 'blue')
    