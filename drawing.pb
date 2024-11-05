Global Dim Palette.l(127), SineHeight.i, SineWidth.i, SineAngle.f

SineHeight = 10
SineWidth = 10
SineAngle = #PI / 50

Macro FastRGB(R, G, B)
  (((R << 8 + G) << 8 ) + B)
EndMacro

Procedure GetBitmapStringWidth(StringToMeasure.s, Scale.i)
  Protected Character.s, Width.i
  
  For i = 1 To Len(StringToMeasure)
    Character = LCase(Mid(StringToMeasure, i, 1))
    If FindMapElement(Font(), Character)
      Width + (Font(Character)\W * Scale)
    Else
      Width + (Font("null")\W * Scale)
    EndIf
  Next
  
  ProcedureReturn Width
EndProcedure

Procedure CreateHeader()
  Protected Character.s, X.i, Y.i = 16, Scale.i = 2, LineText.s
  Dim Header.s(3)
  
  Header(0) = "asio link pro patcher"
  Header(1) = "<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>"
  Header(2) = "brought to you by g.a. collective 2024"
  Header(3) = "<~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~>"
  
  CreateSprite(#SpriteHeader, #ScreenWidth, #ScreenHeight)
  ClearScreen(FastRGB(255, 0, 255))
  
  For LineNumber = 0 To 3
    LineText  = Header(LineNumber)
    LineWidth = GetBitmapStringWidth(LineText, Scale)
    X = (#ScreenWidth - LineWidth) / 2
    
    For i = 1 To Len(LineText)
      Character = LCase(Mid(LineText, i, 1))
      If FindMapElement(Font(), Character)
        ClipSprite(#SpriteFont, Font(Character)\X, Font(Character)\Y, Font(Character)\W, Font(Character)\H)
        ZoomSprite(#SpriteFont, SpriteWidth(#SpriteFont) * Scale, SpriteHeight(#SpriteFont) * Scale)
        DisplayTransparentSprite(#SpriteFont, X, Y)
        X + (Font(Character)\W * Scale)
      Else
        X + (Font("null")\W * Scale)
      EndIf
    Next
    Y + (Font("null")\H * Scale)
  Next
  
  GrabSprite(#SpriteHeader, 0, 0, #ScreenWidth, #ScreenHeight, #PB_Sprite_AlphaBlending)
  TransparentSpriteColor(#SpriteHeader, FastRGB(255, 0, 255))
  ClearScreen(FastRGB(28, 28, 28))
EndProcedure

Procedure DrawHeader()
  Protected Character.s, X.i, OriginalX.i, Y.i = 124, OriginalY.i = Y, Scale.i = 2
  Static Angle.f
  
  Angle + SineAngle
  
  DisplayTransparentSprite(#SpriteHeader, 0, (5*Sin(Angle)))
  
  X = (#ScreenWidth - GetBitmapStringWidth(#Credit, Scale)) / 2
  OriginalX = X
  
  For i = 1 To Len(#Credit)
    Character = LCase(Mid(#Credit, i, 1))
    If FindMapElement(Font(), Character)
      ClipSprite(#SpriteFont, Font(Character)\X, Font(Character)\Y, Font(Character)\W, Font(Character)\H)
      ZoomSprite(#SpriteFont, SpriteWidth(#SpriteFont) * Scale, SpriteHeight(#SpriteFont) * Scale)
      DisplayTransparentSprite(#SpriteFont, X, (Y+SineHeight*Sin(Angle + i / SineWidth)))
      X + (Font(Character)\W * Scale)
    Else
      If Character = "#"
        Y + (Font("null")\H * Scale)
        X = OriginalX
      Else
        X + (Font("null")\W * Scale)
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
; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 69
; FirstLine = 20
; Folding = t
; EnableXP