import std/streams

import googlephotos

let gphoto = newGooglePhotos()

# parse in string chunks
let html = readFile("tests/album.html")
var pos = 0
const chunkSize = 80
while pos <= html.len and gphoto.parseHtml(html[pos ..< min(pos + chunkSize, html.len)]):
  pos.inc(chunkSize)
echo (gphoto.albumInfo.name, gphoto.photos.len, gphoto.photos[0].url)
assert(gphoto.photos.len == gphoto.albumInfo.imageCount)

# parse entire file
gphoto.init()
assert(false == gphoto.parseHtml(html))
echo (gphoto.albumInfo.name, gphoto.photos.len, gphoto.photos[0].url)
assert(gphoto.photos.len == gphoto.albumInfo.imageCount)

# parse from stream (chunked read)
gphoto.init()
let s = newFileStream("tests/album.html")
try:
  assert(false == gphoto.parseHtml(s))
finally:
  s.close()
echo (gphoto.albumInfo.name, gphoto.photos.len, gphoto.photos[0].url)
assert(gphoto.photos.len == gphoto.albumInfo.imageCount)
