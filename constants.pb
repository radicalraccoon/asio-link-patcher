;==========================================================================================================================================================
;-- Parameters
;==========================================================================================================================================================
#Width        = 527
#Height       = 232
#ScreenWidth  = 527
#ScreenHeight = 164

;==========================================================================================================================================================
;-- Identifiers
;==========================================================================================================================================================
Enumeration ; Music
  #Music
EndEnumeration

Enumeration ; Sprites
  #SpriteFont
  #SpritePalette
  #SpriteHeader
EndEnumeration

Enumeration ; Windows
  #WindowMain
EndEnumeration

Enumeration ; Fonts
  #FontUI
EndEnumeration

Enumeration ; Gadgets
  #Option32
  #Option64
  #ButtonPatch
EndEnumeration

;==========================================================================================================================================================
;-- Error Messages
;==========================================================================================================================================================
#Error             = "Error"
#InitScreenError   = "Failed to initialize the screen."
#InitSoundError    = "Failed to initialize the sound environment."
#InitSpriteError   = "Failed to initialize the sprite environment."
#LoadMusicError    = "Failed to load music."
#LoadFontError     = "Failed to load font."
#LoadPaletteError  = "Failed to load palette."
#PatchDataError    = "Failed to find the patch data file."

;==========================================================================================================================================================
;-- Information
;==========================================================================================================================================================
#Title   = "ASIO Link Pro Patcher"
#Credit  = "code::radical raccoon ●●●●●●● music::ultrasyd"

;==========================================================================================================================================================
;-- Patching
;==========================================================================================================================================================
#DefaultPath64 = "Program Files (x86)\ASIOLinkPro\"         : #DefaultPath32 = "Program Files\ASIOLinkPro\"
#Unpatched64   = "7D522A15A51C849DE71D0AC401F4F1BB48761416" : #Unpatched32   = "A883CA9796DAD0AC66CFE96F2B73303D92DB7128"
#Patched64     = "22DEB409824168ACDAE9BBD56EFC9AD8AECA6788" : #Patched32     = "A93489121CBD558F990107E0B9F2BF9FA54635AE"
; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 51
; EnableXP