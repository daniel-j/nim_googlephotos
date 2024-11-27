# Nim Google Photos parser

### Fetches info and photos from public Google Photos album share urls

## Usage

```nim
# create state object (ref object)
let gphoto: GooglePhotos = newGooglePhotos()

# feed html into the parser, can be called multiple times
# returns true while parsing is in progress, returns false when complete or error occured while parsing
# takes string or Stream. Stream variant takes optional chunkSize (default = 1024)
gphoto.parseHtml(input: string): bool
gphoto.parseHtml(s: Stream; chunkSize: int): bool

# call to clean the state/photos stored inside state object
# newGooglePhotos() calls this internally
gphoto.init()

# pass a photo url to this to request a different resolution.
# keeps aspect ratio (contain size), image may be smaller than requested size
googlePhotoUrlSize(url: string; width: int; height: int): string
```

```nim
# following properties are available on the state object:

type
  PhotoInfo* = object
    url*: string
    id*: string
    width*: int
    height*: int
    imageUpdateDate*: BiggestInt
    albumAddDate*: BiggestInt

  AlbumInfo* = object
    name*: string
    id*: string
    createdDate*: BiggestInt
    updatedDate*: BiggestInt
    downloadUrl*: string
    thumbnailUrl*: string
    thumbnailWidth*: int
    thumbnailHeight*: int
    authorName*: string
    authorAvatarUrl*: string
    imageCount*: int
    shareUrl*: string

gphoto.photos: seq[PhotoInfo]
gphoto.albumInfo: AlbumInfo

```

Enjoy!
