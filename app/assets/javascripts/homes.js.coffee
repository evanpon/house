$ ->
  $("a[data-image-id]").hover (e) ->
    e.preventDefault()
    imageId = $(this).data("image-id")
    homeId = $(this).data("home-id")
    url = "https://s3-us-west-2.amazonaws.com/evanpon.applications/house/#{homeId}/#{imageId}"
    $("#image_#{homeId}").attr("src", url)
    $("#image_#{homeId}").show()
    $("#map_#{homeId}").hide()

  $("a[data-map-home-id]").hover (e) ->
    e.preventDefault()
    homeId = $(this).data("map-home-id")
    $("#image_#{homeId}").hide()
    $("#map_#{homeId}").show()

  $("form").on("ajax:success", (e, data, status, xhr) ->
    element = $(this).find(".success")
    element.show().fadeOut(1500)
  ).on "ajax:error", (e, xhr, status, error) ->
    element = $(this).find(".failure")
    element.show().fadeOut(2000)
    