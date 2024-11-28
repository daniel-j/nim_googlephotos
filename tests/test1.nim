import std/streams

import googlephotos

let gphoto = newGooglePhotos()

var photos: seq[PhotoInfo]
var albumInfo: AlbumInfo

gphoto.photoCb = proc (photo: PhotoInfo) =
  echo photo
  photos.add(photo)
gphoto.infoCb = proc (info: AlbumInfo) = albumInfo = info

# parse in string chunks
let html = readFile("tests/album.html")
var pos = 0
const chunkSize = 80
while pos <= html.len and gphoto.parseHtml(html[pos ..< min(pos + chunkSize, html.len)]):
  pos.inc(chunkSize)
echo (albumInfo.name, photos.len, photos[0].url)
assert(photos.len == albumInfo.imageCount)
photos.reset()

# parse entire file
gphoto.init()
assert(false == gphoto.parseHtml(html))
echo (albumInfo.name, photos.len, photos[0].url)
assert(photos.len == albumInfo.imageCount)
photos.reset()

# parse from stream (chunked read)
gphoto.init()
let s = newFileStream("tests/album.html")
try:
  assert(false == gphoto.parseHtml(s))
finally:
  s.close()
echo (albumInfo.name, photos.len, photos[0].url)
assert(photos.len == albumInfo.imageCount)
photos.reset()
