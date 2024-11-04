Global Dim Palette.l(127), SineHeight.i, SineWidth.i, SineAngle.f

SineHeight = 10
SineWidth = 10
SineAngle = #PI / 50

Macro FastRGB(R, G, B)
  (((R << 8 + G) << 8 ) + B)
EndMacro

Procedure CreateHeader()
  Protected Header.s, Character.s, X.i = 11, OriginalX.i = X, Y.i = 16, OriginalY.i = Y
  
  Header = "                asio link pro patcher     #"
  Header + "<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>      #"
  Header + "    brought to you by g.a. collective 2018#"
  Header + "<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>"
  
  CreateSprite(#SpriteHeader, #ScreenWidth, #ScreenHeight)
  ClearScreen(FastRGB(255, 0, 255))
  
  For i = 1 To Len(Header)
    Character = LCase(Mid(Header, i, 1))
    If FindMapElement(Font(), Character)
      ClipSprite(#SpriteFont, Font(Character)\X, Font(Character)\Y, Font(Character)\W, Font(Character)\H)
      ZoomSprite(#SpriteFont, SpriteWidth(#SpriteFont) * 2, SpriteHeight(#SpriteFont) * 2)
      DisplayTransparentSprite(#SpriteFont, X, Y)
      X + ((Font(Character)\W * 2) - 2)
    Else
      If Character = "#"
        Y + 22
        X = OriginalX
      Else
        X + 8
      EndIf
    EndIf
  Next
  
  GrabSprite(#SpriteHeader, 0, 0, #ScreenWidth, #ScreenHeight, #PB_Sprite_AlphaBlending)
  TransparentSpriteColor(#SpriteHeader, FastRGB(255, 0, 255))
  ClearScreen(FastRGB(28, 28, 28))
EndProcedure

Procedure DrawHeader()
  Protected Character.s, X.i = 18, OriginalX.i = X, Y.i = 124, OriginalY.i = Y
  Static Angle.f
  
  Angle + SineAngle
  
  DisplayTransparentSprite(#SpriteHeader, 0, (5*Sin(Angle)))

  For i = 1 To Len(#Credit)
    Character = LCase(Mid(#Credit, i, 1))
    If FindMapElement(Font(), Character)
      ClipSprite(#SpriteFont, Font(Character)\X, Font(Character)\Y, Font(Character)\W, Font(Character)\H)
      ZoomSprite(#SpriteFont, SpriteWidth(#SpriteFont) * 2, SpriteHeight(#SpriteFont) * 2)
      DisplayTransparentSprite(#SpriteFont, X, (Y+SineHeight*Sin(Angle + i / SineWidth)))
      X + ((Font(Character)\W * 2) - 2)
    Else
      If Character = "#"
        Y + 22
        X = OriginalX
      Else
        X + 8
      EndIf
    EndIf
  Next
EndProcedure

Procedure DrawBackground()
  Static A.f, X2.f, Y2.f, V1.f, V2.f, A2.f
  
  StartDrawing(ScreenOutput())
    A2 = A*2
    For X = 3 To 524 Step 3
      X2 = X/2048
      For Y = 3 To 161 Step 3
        Y2 = Y/1024 : V1 = 256+192 * Sin(Y2+A2) : V2 = Sin((A-X2) + Y2)
        M = Round(48 * Sin((X+Y) / V1*V2 ), #PB_Round_Down)
        If Palette(48-M) <> 0
          Plot(X, Y, Palette(48-M))
          Plot(X+1, Y, Palette(48-M))
          Plot(X, Y+1, Palette(48-M))
          Plot(X+1, Y+1, Palette(48-M))
        EndIf
      Next
    Next
  A + 0.0010
  StopDrawing()
EndProcedure

DataSection
  Palette: ; compressed size : 167 bytes // original size : 214 bytes
    Data.q $7474656C626C7A31,$00000000000000D6,$0000000000080000,$960000D64D140042,$000184006C000000
    Data.q $0403010000008000,$0000004000160050,$0300072804030B13,$001B2EE073524742,$002B530004876002
    Data.q $9C005F574F001D00,$C70029ADFF008376,$FFF1E800C20400C3,$002121111110101A,$4333333232222200
    Data.q $6555555454444443,$111C214365180065,$0054444333322221,$3232434354541280,$0000000010102121
    Data.b $01,$23,$45,$65,$43,$21,$00
  PaletteEnd:
EndDataSection
; IDE Options = PureBasic 5.61 (Windows - x86)
; CursorPosition = 76
; Folding = 5
; EnableXP