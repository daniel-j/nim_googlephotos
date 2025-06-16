import std/httpclient

import googlephotos

let gphoto = newGooglePhotos()

var photos: seq[PhotoInfo]
var albumInfo: AlbumInfo

gphoto.photoCb = proc (photo: PhotoInfo) = photos.add(photo)
gphoto.infoCb = proc (info: AlbumInfo) = albumInfo = info


let client = newHttpClient()
echo "fetching..."
let html = client.getContent("https://goo.gl/photos/hALfCAQzUXc8Gtci9")
client.close()
echo "parsing..."
assert(false == gphoto.parseHtml(html))
echo gphoto.state

if photos.len > 0:
  echo (albumInfo.name, photos.len, googlePhotoUrlSize(photos[0].url, 1920, 1080))
  assert(photos.len == albumInfo.imageCount)
else:
  echo "no photos in album"
photos.reset()
