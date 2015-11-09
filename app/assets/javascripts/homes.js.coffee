$ ->
  $("a[data-image-id]").hover (e) ->
    e.preventDefault()
    imageId = $(this).data("image-id")
    homeId = $(this).data("home-id")
    # url = "http://www.rmlsweb.com/V4/subsys/LLPM/photo.aspx?mlsn=#{homeId}&idx=#{imageId}"
    url = "https://s3-us-west-2.amazonaws.com/evanpon.applications/house/#{homeId}/#{imageId}"
    $("#image_#{homeId}").attr("src", url)

  $("form").on("ajax:success", (e, data, status, xhr) ->
    element = $(this).find(".success")
    element.show().fadeOut(1500)
  ).on "ajax:error", (e, xhr, status, error) ->
    element = $(this).find(".failure")
    element.show().fadeOut(2000)
    