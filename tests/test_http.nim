import std/httpclient

import googlephotos

let gphoto = newGooglePhotos()

let client = newHttpClient()
try:
  echo "fetching..."
  let html = client.getContent("https://goo.gl/photos/hALfCAQzUXc8Gtci9")
  echo "parsing..."
  assert(false == gphoto.parseHtml(html))
finally:
  client.close()

echo (gphoto.albumInfo.name, gphoto.photos.len, googlePhotoUrlSize(gphoto.photos[0].url, 1920, 1080))
assert(gphoto.photos.len == gphoto.albumInfo.imageCount)
