import std/strutils
import std/json
import std/streams

type
  ParseState = enum
    Invalid
    SeekPatternInitial = "id=\"_ij\""
    SeekPatternPhotos = "data:[null,[[\""
    ReadPhoto = "\"]}]"
    SeekPatternAlbumInfo = "[\""
    ReadAlbumInfo = ",null,0], sideChannel"
    Complete

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

  GooglePhotos* = ref object
    photos*: seq[PhotoInfo]
    albumInfo*: AlbumInfo
    state: ParseState
    str: string

proc init*(self: GooglePhotos) =
  self.state = SeekPatternInitial
  self.str = ""
  self.photos.setLen(0)
  self.albumInfo.reset()

proc newGooglePhotos*(): GooglePhotos =
  new(result)
  result.init()

proc parseHtml*(self: GooglePhotos; input: string): bool =
  ## supports chunked parsing
  if self.state == Invalid: return false

  self.str &= input
  if self.str.len == 0: return false

  case self.state:
  of Invalid:
    echo "invalid!"
    return false

  of SeekPatternInitial:
    var linei = 0
    var le = self.str.find($SeekPatternInitial)
    if le == -1:
      self.str = self.str[max(0, self.str.len - static(($SeekPatternInitial).len)) .. ^1]
    else:
      linei.inc(le)
      self.str = self.str[(linei + static(($SeekPatternInitial).len)) .. ^1]
      self.state = SeekPatternPhotos
      return self.parseHtml("")

  of SeekPatternPhotos:
    var linei = 0
    var le = self.str.find($SeekPatternPhotos)
    if le == -1:
      self.str = self.str[max(0, self.str.len - static(($SeekPatternPhotos).len)) .. ^1]
    else:
      linei.inc(le)
      self.str = self.str[(linei + static(($SeekPatternPhotos).len - 2)) .. ^1]
      self.state = ReadPhoto
      self.photos.setLen(0)
      return self.parseHtml("")

  of ReadPhoto:
    var linei = 0
    var le = self.str.find($ReadPhoto)
    if le == -1 or self.str.len <= le + static(($ReadPhoto).len):
      discard
    else:
      linei.inc(le)
      let photodata = self.str[0 ..< (linei + static(($ReadPhoto).len))]
      let photoInfoJson = parseJson(photodata)
      self.photos.add(PhotoInfo(
        id: photoInfoJson[0].getStr(),
        url: photoInfoJson[1][0].getStr(),
        width: photoInfoJson[1][1].getInt(),
        height: photoInfoJson[1][2].getInt(),
        imageUpdateDate: photoInfoJson[2].getBiggestInt(),
        albumAddDate: photoInfoJson[5].getBiggestInt()
      ))
      self.str = self.str[photodata.len .. ^1]
      if self.str[0] == ',':
        self.str = self.str[1 .. ^1]
      else:
        self.state = SeekPatternAlbumInfo
      return self.parseHtml("")

  of SeekPatternAlbumInfo:
    var linei = 0
    var le = self.str.find($SeekPatternAlbumInfo)
    if le == -1:
      self.str = self.str[max(0, self.str.len - static(($SeekPatternAlbumInfo).len)) .. ^1]
    else:
      linei.inc(le)
      self.str = self.str[linei .. ^1]
      self.state = ReadAlbumInfo
      return self.parseHtml("")

  of ReadAlbumInfo:
    var linei = 0
    var le = self.str.find($ReadAlbumInfo)
    if le == -1:
      discard
    else:
      linei.inc(le)
      let albuminfo = self.str[0 ..< linei]
      let albumInfoJson = parseJson(albumInfo)
      self.albumInfo = AlbumInfo(
        id: albumInfoJson[0].getStr(),
        name: albumInfoJson[1].getStr(),
        createdDate: albumInfoJson[2][0].getBiggestInt(), # maybe?
        updatedDate: albumInfoJson[2][1].getBiggestInt(), # maybe?
        downloadUrl: albumInfoJson[3].getStr(),
        thumbnailUrl: albumInfoJson[4][0].getStr(),
        thumbnailWidth: albumInfoJson[4][1].getInt(),
        thumbnailHeight: albumInfoJson[4][2].getInt(),
        authorName: albumInfoJson[5][11][0].getStr(),
        authorAvatarUrl: albumInfoJson[5][12][0].getStr(),
        imageCount: albumInfoJson[21].getInt(),
        shareUrl: albumInfoJson[32].getStr()
      )
      self.str = ""
      self.state = Complete
      return self.parseHtml("")

  of Complete:
    self.str = ""
    return false

  return true

proc parseHtml*(self: GooglePhotos; s: Stream; chunkSize: int = 1024): bool =
  result = true
  var buffer = newStringOfCap(chunkSize)
  buffer.setLen(1)
  while not s.atEnd() and result:
    let l = s.readData(addr(buffer[0]), chunkSize)
    if l <= 0:
      result = true
      break
    buffer.setLen(l)
    result = self.parseHtml(buffer)

proc googlePhotoUrlSize*(url: string; width: int; height: int): string =
  return url & "=w" & $width & "-h" & $height
