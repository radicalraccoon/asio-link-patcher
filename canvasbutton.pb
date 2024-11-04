; Canvas based Button (Button, Checkbox, Option, Toggle, Image, DropDown)
; By Said, works with PB 5.22 LTS / PB 5.30 onward
; Tested on win/osx x86/x64 ascii/unicode
; (http://www.purebasic.fr/english/viewtopic.php?f=12&t=62198)
;
; Modified by Radical Raccoon to add additional properties and stop the module from handling toggles.
; Manually doing this is better For my use case. ( Tested with PB 5.61 and 5.62 )

DeclareModule MyButton
    #Type_Normal            = 0     ; not a toggle button - default
    #Type_DropList          = 1     ; normal with drop down menu/list
    #Type_Toggle            = 2     ; flat toggle button (behaves like a checkbox)
    #Type_Checkbox          = 3     ; checkbox
    #Type_Radio             = 4     ; radio/option button
    #Type_ToggleRadio       = 5     ; flat toggle button (behaves like a radio/option)
   
    ; Properties/Attributes - Set/Get
    Enumeration
        #Prop_BackColor   = 0   ; internal back/main color
        #Prop_HoverBackColor    ; internal back/main color on hover
        #Prop_ClickBackColor    ; internal back/main color on click
        #Prop_OutColor          ; external back color
        #Prop_BorderColor       ;
        #Prop_TextColor         ;
        #Prop_HoverTextColor    ;
        #Prop_ClickTextColor    ;
        #Prop_Align             ; #PB_Text_Center or #PB_Text_Right (for Left-align use 0)
        #Prop_Type              ; one of #Type_xxx
        #Prop_Gradient          ; 0...100
        #Prop_Radius            ; as defined with RoundBox()
        #Prop_Font              ; PB font number
        #Prop_Menu              ; PB menu number
        #Prop_Text              ;
        #Prop_Image             ; PB image number
        #Prop_ImageFit          ; image fixed/resizable
       
        #Prop_State             ; mouse state
        #Prop_Checked           ; 0/1
       
        #Prop_OnClick           ;
    EndEnumeration
   
    Declare.i ResetTemplate()
    Declare.i SetTemplate(Property, Value)                  ; changes one of the default properties - not related to any button in particular
   
    Declare.i SetProperty(Gadget, Property, Value)
    Declare.i GetProperty(Gadget, Property)
    Declare.i SetText(Gadget, Text.s)
    Declare.s GetText(Gadget)
    Declare.i Check(Gadget, State = #True)
    Declare.i Enable(Gadget, State = #True)
    Declare.i IsChecked(Gadget)
    Declare.i IsEnabled(Gadget)
    Declare.i Free(Gadget)
    Declare.i Resize(Gadget, X, Y, Width, Height)
    Declare.i New(Gadget, X, Y, W, H, Text.s, Tip.s="")
    Declare.i Click(Gadget)                                 ; simualtes a click from code
   
EndDeclareModule

Module MyButton
    EnableExplicit
   
    #Text_MarginX          = 4     ; left/right margin of text n pixel
    #Text_MarginY          = 1     ; up/down margin in pixel
   
    #Width_Checkbox         = 16    ; width of the checkbox/radio area
    #Width_DropDown         = 20    ; width of the drop-down arrow area
   
    Enumeration                 ; Canvas Button State
        #State_MouseOut  = 0    ; normal
        #State_MouseIn          ; hoover
        #State_MouseClick       ; button being clicked/pushed
        #State_Disabled         ;
    EndEnumeration
   
   
    Global Color_Disabled   = $00707070
    Global Color_Hoover     = $FBEEEEAF
    Global Color_Pushed     = $FBE16941
   
    Global TextColorPushed  = $00FFFFFF
    Global TextColorHoover  = $00000000
   
    Prototype.i _OnClickProto()
   
    Structure TMyButton
       
        Gadget.i                ; associated canvas gagdet number
        Type.i                  ; #Type_xxx
        BackColor.i             ; main/back color
        HoverBackColor.i        ; main/back color on hover
        ClickBackColor.i        ; main/back color on click
        CornerColor.i           ; 4-Corners back color / useful if rounded corner Radius > 0
        BorderColor.i           ; border color (-1 : no border)
        TextColor.i             ; front or text color
        HoverTextColor.i        ; front or text color on hover
        ClickTextColor.i        ; front or text color on click
        Align.i                 ; 0/#PB_Text_Center/#PB_Text_Right/
        Gradient.i              ; Gradient level 0..100
        Radius.i                ; X/Y radius
        Font.i                  ; PB font number
        Image.i                 ; PB image number
        ImageFit.i              ; 0/1
        Menu.i                  ; PB popupmenu number
        Text.s                  ; text
        OnClick._OnClickProto   ; routine to call when button receives full click (is pushed/checked/...)
       
        ;
        Checked.i               ; 0/1 valid for toggle button
        State.i                 ; #Prop_State_xxx : current mouse state
       
    EndStructure
   
    Global  MBN_TL.TMyButton    ; current button-template: contains default attrib values - can be changed by code (private to this module)
   
    ;---<<<====>>> helpers
    Procedure.i _MyBlendColor(Color1, Color2, Scale=50)
        Protected R1, G1, B1, R2, G2, B2, Scl.f = Scale/100
       
        R1 = Red(Color1): G1 = Green(Color1): B1 = Blue(Color1)
        R2 = Red(Color2): G2 = Green(Color2): B2 = Blue(Color2)
        ProcedureReturn RGB((R1*Scl) + (R2 * (1-Scl)), (G1*Scl) + (G2 * (1-Scl)), (B1*Scl) + (B2 * (1-Scl)))
       
    EndProcedure
    Procedure.i _MyDrawText(Txt.s,X,Y,W,H, MrgnX,MrgnY, Algn=0,Wrap=0)
        Protected x1,x2,y1,y2, mx,aw,my,ah
        Protected i,j,n,ww,hh,x0,w0
       
        mx = MrgnX          ; default X-horizontal margin left/right
        my = MrgnY          ; default Y-vertical margin up/down
        aw = W - 2*mx       ; actual given width for drawing
        ah = H - 2*my       ; actual given height for drawing
        n = Len(Txt)
       
        If aw <= 0 Or ah <= 0 Or n <= 0 : ProcedureReturn : EndIf
       
        ww = TextWidth(Txt) 
        hh = TextHeight(Txt)
        If ww <= aw And hh <= ah
            ; we have enough room to write straight forward ...
            If algn = 0
                x1 = x + mx
            ElseIf algn = #PB_Text_Right
                x1 = x + mx + (aw - ww)
            ElseIf algn = #PB_Text_Center
                x1 = x + mx + ((aw - ww)/2)
            EndIf
            y1 = y + my + ((ah - hh)/2)
            DrawText(x1,y1,Txt)
            ProcedureReturn
        Else
            If wrap
                ; we might need to wrap text on another line ... when wrapping we do not consider alignment (for now!)
                n = Len(txt)
                x1 = x + mx : x2 = x1 + aw
                y1 = y + my : y2 = y1 + ah
               
                Protected sWrd,eWrd,wWrd, nn, tWrd.s, cc.s
               
                wWrd = 0 : sWrd = 1: eWrd = 0
                For i=1 To n
                    If Mid(txt, i, 1) = " " Or i=n: eWrd = i : EndIf
                   
                    If eWrd > 0 ; we draw that current wrd
                        Repeat
                            tWrd = Mid(txt, sWrd, eWrd-sWrd+1)
                            wWrd = TextWidth(tWrd)
                           
                            If x1 + wWrd <= x2
                                x1 = DrawText(x1,y1,tWrd)
                                sWrd = eWrd + 1: eWrd = 0
                            Else
                                If wWrd <= aw
                                    x1 = x + mx         ; moving to a new line
                                    y1 = y1 + (hh + my)
                                    If (y1+hh) > y2  : Break : EndIf
                                    x1 = DrawText(x1,y1,tWrd)
                                    sWrd = eWrd + 1: eWrd = 0
                                Else
                                    ; we draw char by char
                                    nn = Len(tWrd)
                                    For j=1 To nn
                                        cc = Mid(tWrd,j,1)
                                        If x1 + TextWidth(cc) <= x2
                                            x1 = DrawText(x1,y1,cc)
                                            sWrd = sWrd + 1
                                            If j = nn : eWrd = 0: EndIf
                                        Else
                                            x1 = x + mx         ; moving to a new line
                                            y1 = y1 + (hh + my)
                                            Break
                                        EndIf
                                    Next
                                EndIf
                            EndIf
                            If (y1+hh) > y2  : Break : EndIf
                        Until sWrd > eWrd
                       
                    EndIf
                    If (y1+hh) > y2  : Break : EndIf
                Next
               
            Else
                x1 = x + mx : x2 = x1 + aw
                y1 = y + my : y2 = y1 + ah
                i  = 0
                Repeat
                    i = i + 1
                    If i > n    : Break : EndIf
                    w0 = TextWidth(Mid(txt, i, 1))
                    If x1 + w0 > x2 : Break : EndIf
                    x1 = DrawText(x1,y1,Mid(txt, i, 1))
                ForEver
            EndIf
        EndIf
       
    EndProcedure     
    Procedure.i _MyDrawCheckBox(x,y,w,h, boxWidth, enabled, checked=#False)
        ; draw a check-box /(x,y,w,h) is the area given for drawing checkbox... assumes a StartDrawing!
        Protected ww,hh, x0,y0,xa,ya,xb,yb,xc,yc, bdColor = $CD0000
       
        ww = boxWidth : hh = boxWidth
        If ww <= w And hh <= h
            x0 = x + ((w - ww) / 2)
            y0 = y + ((h - hh) / 2)
            If enabled = #False : bdColor = $9F9F9F : EndIf
            DrawingMode(#PB_2DDrawing_Default)
            Box(x0  ,y0  ,ww  ,hh  ,bdColor)
            Box(x0+1,y0+1,ww-2,hh-2,$D4D4D4)
            Box(x0+2,y0+2,ww-4,hh-4,$FFFFFF)
            ;
            If checked
                xb = x0 + (ww / 2) - 1  :   yb = y0 + hh - 5
                xa = x0 + 4             :   ya = yb - xb + xa
                xc = x0 + ww - 4        :   yc = yb + xb - xc
               
                FrontColor($12A43A)
                LineXY(xb,yb  ,xa,ya  ) :   LineXY(xb,yb  ,xc,yc  )
                LineXY(xb,yb-1,xa,ya-1) :   LineXY(xb,yb-1,xc,yc-1) ; move up by 1
                LineXY(xb,yb-2,xa,ya-2) :   LineXY(xb,yb-2,xc,yc-2) ; move up by 2
            EndIf
        EndIf
       
    EndProcedure
    Procedure.i _MyDrawRadio(x,y,w,h, boxWidth, enabled, checked=#False)
        ; draw a radio/option /(x,y,w,h) is the area reserved to draw checkbox... assumes a StartDrawing!
        Protected ww,hh, x0,y0, bdColor = $CD0000
       
        ww = boxWidth : hh = boxWidth
        If ww <= w And hh <= h
            x0 = x + w/2 ;((w - ww) / 2)
            y0 = y + h/2 ;((h - hh) / 2)
            If enabled = #False : bdColor = $9F9F9F : EndIf
           
            DrawingMode(#PB_2DDrawing_Default)
            Circle(x0, y0, boxWidth/2, bdColor)
            Circle(x0, y0, boxWidth/2 - 2, $FFFFFF)
            If checked
                FrontColor($12A43A): Circle(x0, y0, 3)
            EndIf
        EndIf
       
    EndProcedure
    Procedure.i _MyDrawComboArrow(x,y,w,h, withBkg=#False)
        ; draw a combo-box-arrow (x,y,w,h) is the area given for drawing .. assumes a StartDrawing!
        Protected x0,y0,ww,hh
       
        ww = 7
        hh = 4
        If ww < w And hh < h
            If withBkg
                DrawingMode(#PB_2DDrawing_Gradient)
                BackColor(RGB(224, 226, 226)) : FrontColor(RGB(201, 201, 201)) : LinearGradient(X,Y,X,Y+H/2)
                Box(x+3,y+3,w-5,h-5)
            EndIf
           
            DrawingMode(#PB_2DDrawing_Default): FrontColor($CD0000)
            Line(x,y+4,1,h-8)
           
            x0 = x + (w - ww)/2
            y0 = y + (h - hh)/2 - 1
            Line(x0  ,y0  ,ww  ,1)
            Line(x0+1,y0+1,ww-2,1)
            Line(x0+2,y0+2,ww-4,1)
            Line(x0+3,y0+3,ww-6,1)
        EndIf
       
    EndProcedure
   
    ;---<<<====>>> core
    Procedure   Draw(*mbn.TMyButton)
        Protected w,h,x,y, w1,h1,gdt, x0, w0, enabled
        Protected gC0,gC1,n,tColor,brdColor,inColor ; gradient details and text colors
       
        If *mbn = 0 : ProcedureReturn : EndIf
        gdt = *mbn\Gadget
        If StartDrawing(CanvasOutput(gdt)) = 0 : ProcedureReturn : EndIf
       
        w = GadgetWidth(gdt): h = GadgetHeight(gdt)
        ; common to all cases
        DrawingMode(#PB_2DDrawing_Default)  : Box(0,0,w,h,*mbn\CornerColor)
       
        enabled = #True : n = 2
        If *mbn\State = #State_Disabled
            enabled = #False
            gC0 = $B8B8B8: gC1 = Color_Disabled: n = 1: tColor = $C4C4C4
        EndIf
       
        If *mbn\State = #State_MouseIn
            ;gC0 = $FFFFFF: gC1 = Color_Hoover: n = 2: tColor = $000000
            gC1 = *mbn\HoverBackColor: n = 2: tColor = *mbn\HoverTextColor
            gC0 = _MyBlendColor($FFFFFF, Color_Hoover, *mbn\Gradient)
        EndIf   
        If *mbn\State = #State_MouseOut
            gC1 = *mbn\BackColor: n = 2: tColor = *mbn\TextColor
            gC0 = _MyBlendColor($FFFFFF, *mbn\BackColor, *mbn\Gradient)
        EndIf
        If (*mbn\State = #State_MouseClick) Or ((*mbn\Type = #Type_Toggle) And *mbn\Checked) Or ((*mbn\Type = #Type_ToggleRadio) And *mbn\Checked)
            gC1 = *mbn\ClickBackColor: gC0 = $FFFFFF: n = 3: tColor = *mbn\ClickTextColor
        EndIf
       
        FrontColor(gC1)
        If *mbn\Gradient > 0
            BackColor(gC0) : LinearGradient(0,0,0,h/n)
            DrawingMode(#PB_2DDrawing_Gradient)
        Else
            DrawingMode(#PB_2DDrawing_Default)
        EndIf
        RoundBox(0,0,w,h,*mbn\Radius,*mbn\Radius)
       
       
        ; decoration & text
        If IsImage(*mbn\Image)
            If *mbn\ImageFit
                DrawImage(ImageID(*mbn\Image), 4,4,w-8,h-8)      ; resize/fit
            Else
                ; fixed size
                DrawingMode(#PB_2DDrawing_AlphaBlend)
                w1 = (w - ImageWidth( *mbn\Image))/2 : If w1 < 0 : w1 = 0 : EndIf
                h1 = (h - ImageHeight(*mbn\Image))/2 : If h1 < 0 : h1 = 0 : EndIf
                DrawImage(ImageID(*mbn\Image), w1, h1)
            EndIf
        EndIf
        Select *mbn\Type
            Case #Type_Normal, #Type_Toggle, #Type_ToggleRadio
                If *mbn\Text  <> ""
                    DrawingMode(#PB_2DDrawing_Transparent) : FrontColor(tColor)
                    If IsFont(*mbn\Font) : DrawingFont(FontID(*mbn\Font)) : EndIf
                    _MyDrawText(*mbn\Text,0,0,w,h, #Text_MarginX,#Text_MarginY, *mbn\Align)
                EndIf
               
            Case #Type_Checkbox
                _MyDrawCheckBox(#Text_MarginX, 0, #Width_Checkbox, h, #Width_Checkbox, enabled, *mbn\Checked)
                If *mbn\Text  <> ""
                    DrawingMode(#PB_2DDrawing_Transparent) : FrontColor(tColor)
                    If IsFont(*mbn\Font) : DrawingFont(FontID(*mbn\Font)) : EndIf
                    x0 = #Text_MarginX + #Width_Checkbox
                    w0 = w - x0
                    _MyDrawText(*mbn\Text,x0,0,w0,h, #Text_MarginX,#Text_MarginY, *mbn\Align)
                EndIf
               
            Case #Type_Radio
                _MyDrawRadio(#Text_MarginX, 0, #Width_Checkbox, h, #Width_Checkbox, enabled, *mbn\Checked)
                If *mbn\Text  <> ""
                    DrawingMode(#PB_2DDrawing_Transparent) : FrontColor(tColor)
                    If IsFont(*mbn\Font) : DrawingFont(FontID(*mbn\Font)) : EndIf
                    x0 = #Text_MarginX + #Width_Checkbox
                    w0 = w - x0
                    _MyDrawText(*mbn\Text,x0,0,w0,h, #Text_MarginX,#Text_MarginY, *mbn\Align)
                EndIf
               
            Case #Type_DropList
                _MyDrawComboArrow(w-#Width_DropDown, 0, #Width_DropDown, h)
                If *mbn\Text  <> ""
                    DrawingMode(#PB_2DDrawing_Transparent) : FrontColor(tColor)
                    If IsFont(*mbn\Font) : DrawingFont(FontID(*mbn\Font)) : EndIf
                    w0 = w - #Width_DropDown
                    _MyDrawText(*mbn\Text,0,0,w0,h, #Text_MarginX,#Text_MarginY, *mbn\Align)
                EndIf
        EndSelect
       
        ; common to all cases
        If *mbn\BorderColor >= 0
            DrawingMode(#PB_2DDrawing_Outlined)
            RoundBox(0,0,w,h,*mbn\Radius,*mbn\Radius,*mbn\BorderColor)
        EndIf
        StopDrawing()
       
    EndProcedure
    Procedure.i ManageEvent(Gadget, EvnTp)
        ; manages the new event, update state ... and return True if btn is clicked => we shall process
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
        Protected prvState,mx,my,dd, isClicked
       
        If *mbn = 0 : ProcedureReturn #False : EndIf
       
        If *mbn\State = #State_Disabled : ProcedureReturn #False : EndIf
        prvState = *mbn\State
       
        Select evnTp
               
            Case #PB_EventType_Input
                If Chr(GetGadgetAttribute(Gadget, #PB_Canvas_Input)) = " "
                    *mbn\Checked = Bool(*mbn\Checked XOr #True)
                    *mbn\State = #State_MouseOut
                    isClicked = #True                         ; this will be returned for processing
                EndIf
               
            Case #PB_EventType_KeyDown
                If GetGadgetAttribute(Gadget, #PB_Canvas_Key ) = #PB_Shortcut_Return
                    *mbn\Checked = Bool(*mbn\Checked XOr #True)
                    *mbn\State = #State_MouseOut
                    isClicked = #True                         ; this will be returned for processing
                EndIf
               
            Case #PB_EventType_MouseEnter
                *mbn\State  = #State_MouseIn
               
            Case #PB_EventType_MouseMove  ; we need this because mouse-up is received before mouse-leave
                If *mbn\State <> #State_MouseClick
                    *mbn\State = #State_MouseIn
                EndIf
               
            Case #PB_EventType_MouseLeave
                *mbn\State  = #State_MouseOut
               
            Case  #PB_EventType_LeftButtonDown
                *mbn\State  = #State_MouseClick
               
            Case #PB_EventType_LeftButtonUp
                mx = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX)
                my = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
                If  (mx < GadgetWidth(Gadget)) And (my < GadgetHeight(Gadget))  And (mx >= 0) And (my >= 0)
                    If (prvState = #State_MouseClick)
                        isClicked    = #True       ; this will be returned for processing
                                                   ;*mbn\State   = #State_MouseIn
                        *mbn\State   = #State_MouseOut
                        Select *mbn\Type
                            Case #Type_Toggle, #Type_Checkbox
                                ;*mbn\Checked = Bool(*mbn\Checked XOr #True)
                            Case #Type_Radio, #Type_ToggleRadio
                                ;*mbn\Checked = #True
                            Case #Type_DropList
                                dd = GadgetWidth(Gadget) - mx
                                If IsMenu(*mbn\Menu) And (dd < #Width_DropDown)
                                    DisplayPopupMenu(*mbn\Menu, WindowID(GetActiveWindow()))
                                EndIf
                        EndSelect
                    EndIf
                EndIf
            Default
                ProcedureReturn #False
        EndSelect
       
        ; we draw if need be (new difeerent state) or checking changed
        If isClicked Or (prvState <> *mbn\State)
            Draw(*mbn)
        EndIf
       
        ; isClicked = True => a full click has been received by this button, ready for processing
        ProcedureReturn isClicked
       
    EndProcedure
   
    Procedure.i HandleEvents()
        If ManageEvent(EventGadget(), EventType())
            Protected *mbn.TMyButton = GetGadgetData(EventGadget())
            ;Debug " Clicked : " + *mbn\Text
            If *mbn\OnClick
                *mbn\OnClick()
            EndIf
        EndIf
       
    EndProcedure
    Procedure.i Click(Gadget)
        ; simulates a click, can be callad from code
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
       
        If *mbn
            If *mbn\OnClick : *mbn\OnClick() : EndIf
        EndIf
       
    EndProcedure
   
    Procedure.i ResetTemplate()
        MBN_TL\Gadget         = -1
        MBN_TL\Type           = #Type_Normal
        MBN_TL\BackColor      = $3C3C3C
        MBN_TL\HoverBackColor = $FFAD25
        MBN_TL\ClickBackColor = $3C3C3C
        MBN_TL\CornerColor    = $1C1C1C
        MBN_TL\BorderColor    = $0C0C0C
        MBN_TL\TextColor      = $6E6E6E
        MBN_TL\HoverTextColor = $1C1C1C
        MBN_TL\ClickTextColor = $6E6E6E
        MBN_TL\Align          = #PB_Text_Center
        MBN_TL\Gradient       = 0
        MBN_TL\Radius         = 0
        MBN_TL\Font           = -1
        MBN_TL\Image          = -1
        MBN_TL\ImageFit       = 0
        MBN_TL\Menu           = -1
        MBN_TL\Text           = "Button"
        MBN_TL\Checked        = #False
        MBN_TL\State          = #State_MouseOut
    EndProcedure
    Procedure.i SetTemplate(Property, Value)
        ; revise the default current template
        Select Property
            Case #Prop_BackColor      : MBN_TL\BackColor      = Value
            Case #Prop_HoverBackColor : MBN_TL\HoverBackColor = Value
            Case #Prop_ClickBackColor : MBN_TL\ClickBackColor = Value
            Case #Prop_OutColor       : MBN_TL\CornerColor    = Value
            Case #Prop_BorderColor    : MBN_TL\BorderColor    = Value
            Case #Prop_TextColor      : MBN_TL\TextColor      = Value
            Case #Prop_HoverTextColor : MBN_TL\HoverTextColor = Value
            Case #Prop_ClickTextColor : MBN_TL\ClickTextColor = Value
            Case #Prop_Font           : MBN_TL\Font           = Value
            Case #Prop_Radius         : MBN_TL\Radius         = Value
            Case #Prop_Align          : MBN_TL\Align          = Value
            Case #Prop_Type           : MBN_TL\Type           = Value
            Case #Prop_Image          : MBN_TL\Image          = Value
            Case #Prop_ImageFit       : MBN_TL\ImageFit       = Value
            Case #Prop_Menu           : MBN_TL\Menu           = Value
            Case #Prop_State          : MBN_TL\State          = Value
            Case #Prop_Checked        : MBN_TL\Checked        = Value
            Case #Prop_Gradient       : MBN_TL\Gradient       = Value
                ;                                             If Value > 100 : Value = 100 : EndIf
                ;                                             If Value <   0 : Value =   0 : EndIf
            Default
                ProcedureReturn
        EndSelect
       
    EndProcedure
   
    Procedure.i SetProperty(Gadget, Property, Value)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
       
        Select Property
            Case #Prop_BackColor      : *mbn\BackColor      = Value
            Case #Prop_HoverBackColor : *mbn\HoverBackColor = Value
            Case #Prop_ClickBackColor : *mbn\ClickBackColor = Value
            Case #Prop_OutColor       : *mbn\CornerColor    = Value
            Case #Prop_BorderColor    : *mbn\BorderColor    = Value
            Case #Prop_TextColor      : *mbn\TextColor      = Value
            Case #Prop_HoverTextColor : *mbn\HoverTextColor = Value
            Case #Prop_ClickTextColor : *mbn\ClickTextcolor = Value
            Case #Prop_Font           : *mbn\Font           = Value
            Case #Prop_Radius         : *mbn\Radius         = Value
            Case #Prop_Align          : *mbn\Align          = Value
            Case #Prop_Type           : *mbn\Type           = Value
            Case #Prop_Image          : *mbn\Image          = Value
            Case #Prop_ImageFit       : *mbn\ImageFit       = Bool(Value)
            Case #Prop_Menu           : *mbn\Menu           = Value
            Case #Prop_State          : *mbn\State          = Value
            Case #Prop_Checked        : *mbn\Checked        = Value
            Case #Prop_Gradient       : *mbn\Gradient       = Value
            Case #Prop_OnClick        : *mbn\OnClick        = Value
            Default                   : ProcedureReturn                   ; no need to draw
        EndSelect
        SetTemplate(Property, Value)
        Draw(*mbn)
       
    EndProcedure
    Procedure.i GetProperty(Gadget, Property)
        Protected Value = -1, *mbn.TMyButton = GetGadgetData(Gadget)
       
        Select Property
            Case #Prop_BackColor    : Value = *mbn\BackColor
            Case #Prop_OutColor     : Value = *mbn\CornerColor
            Case #Prop_BorderColor  : Value = *mbn\BorderColor
            Case #Prop_TextColor    : Value = *mbn\TextColor
            Case #Prop_Font         : Value = *mbn\Font
            Case #Prop_Radius       : Value = *mbn\Radius
            Case #Prop_Align        : Value = *mbn\Align
            Case #Prop_Type         : Value = *mbn\Type
            Case #Prop_Image        : Value = *mbn\Image
            Case #Prop_ImageFit     : Value = *mbn\ImageFit
            Case #Prop_Menu         : Value = *mbn\Menu
            Case #Prop_State        : Value = *mbn\State
            Case #Prop_Checked      : Value = *mbn\Checked
            Case #Prop_Gradient     : Value = *mbn\Gradient
            Case #Prop_OnClick      : Value = *mbn\OnClick
        EndSelect
        ProcedureReturn Value
       
    EndProcedure
    Procedure.i SetText(Gadget, Text.s)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
       
        *mbn\Text = Text
        Draw(*mbn)
    EndProcedure
    Procedure.s GetText(Gadget)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
       
        ProcedureReturn *mbn\Text
    EndProcedure
    Procedure.i Check(Gadget, State = #True)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
       
        If *mbn = 0 : ProcedureReturn  : EndIf
        If *mbn\Type > #Type_DropList
            *mbn\Checked = State
            Draw(*mbn)
        EndIf
    EndProcedure
    Procedure.i Enable(Gadget, State = #True)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
        If *mbn = 0                      : ProcedureReturn  : EndIf
        If State
            *mbn\State = #State_MouseOut
        Else
            *mbn\State = #State_Disabled
        EndIf
        DisableGadget(Gadget, Bool(Not State))
        Draw(*mbn)
       
    EndProcedure
    Procedure.i IsChecked(Gadget)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
        If *mbn = 0 : ProcedureReturn #False   : EndIf
        If *mbn\Type  > #Type_DropList And *mbn\Checked  : ProcedureReturn #True    : EndIf
        ProcedureReturn #False
    EndProcedure
    Procedure.i IsEnabled(Gadget)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
        If *mbn = 0                         : ProcedureReturn #False   : EndIf
        If *mbn\State <> #State_Disabled : ProcedureReturn #True    : EndIf
        ProcedureReturn #False
    EndProcedure
    Procedure.i Free(Gadget)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
       
        If *mbn
            UnbindGadgetEvent(Gadget, @HandleEvents())
            ClearStructure(*mbn, TMyButton)
            FreeMemory(*mbn)
        EndIf
        FreeGadget(Gadget)
    EndProcedure
    Procedure.i Resize(Gadget, X, Y, Width, Height)
        Protected *mbn.TMyButton = GetGadgetData(Gadget)
       
        ResizeGadget(Gadget, X, Y, Width, Height)
        Draw(*mbn)
    EndProcedure
   
    Procedure.i New(Gadget, X, Y, W, H, Text.s, Tip.s="")
        ; new button as per current default settings in template whatever they are
        Protected Button, *mbn.TMyButton
       
        Button = CanvasGadget(Gadget, X, Y, W, H, #PB_Canvas_Keyboard);|#PB_Canvas_DrawFocus)
        If Button
            If Gadget <> #PB_Any  : Button = Gadget : EndIf
           
            *mbn = AllocateMemory(SizeOf(TMyButton))
            InitializeStructure(*mbn, TMyButton)
            CopyStructure(@MBN_TL, *mbn, TMyButton)
           
            *mbn\Gadget     = Button
            *mbn\Checked    = #False
            *mbn\State      = #State_MouseOut
            *mbn\Text       = Text
            *mbn\OnClick    = 0
            SetGadgetData(Button, *mbn)
            SetGadgetAttribute(Button,#PB_Canvas_Cursor,#PB_Cursor_Hand)
            GadgetToolTip(Button, Tip)
            BindGadgetEvent(Button, @HandleEvents())
            Draw(*mbn)
        EndIf
       
        ProcedureReturn Button
       
    EndProcedure
   
    ; call ResetTemplate()
    ResetTemplate()
   
EndModule


;---<<<====>>> examples and special pre-set cases
CompilerIf #PB_Compiler_IsMainFile
   
    UsePNGImageDecoder()
   
    Procedure.i MyButton_Dropdown(Gadget, X, Y, Width, Height, Menu, Text.s)
        MyButton::SetTemplate(MyButton::#Prop_Type, MyButton::#Type_DropList)
        MyButton::SetTemplate(MyButton::#Prop_Align, #PB_Text_Center)
        MyButton::SetTemplate(MyButton::#Prop_Menu, Menu)
       
        ProcedureReturn MyButton::New(Gadget, X, Y, Width, Height, Text)
       
    EndProcedure
    Procedure.i MyButton_Toggle(Gadget, X, Y, Width, Height, Text.s)
        ; toggle button
        MyButton::SetTemplate(MyButton::#Prop_Type, MyButton::#Type_Toggle)
        MyButton::SetTemplate(MyButton::#Prop_Align, #PB_Text_Center)
       
        ProcedureReturn MyButton::New(Gadget, X, Y, Width, Height,Text)
       
    EndProcedure
    Procedure.i MyButton_Checkbox(Gadget, X, Y, Width, Height, Text.s)
       
        MyButton::SetTemplate(MyButton::#Prop_Align, 0)
        MyButton::SetTemplate(MyButton::#Prop_Type, MyButton::#Type_Checkbox)
        MyButton::SetTemplate(MyButton::#Prop_BackColor, RGB(255, 0,0))
       
        ProcedureReturn MyButton::New(Gadget, X, Y, Width, Height,Text)
       
    EndProcedure
    Procedure.i MyButton_Option(Gadget, X, Y, Width, Height, Text.s)
        MyButton::SetTemplate(MyButton::#Prop_Align, 0)
        MyButton::SetTemplate(MyButton::#Prop_Type, MyButton::#Type_Radio)
       
        ProcedureReturn MyButton::New(Gadget, X, Y, Width, Height,Text)
       
    EndProcedure
    Procedure.i MyButton_Flat(Gadget, X, Y, Width, Height, Text.s)
        ; flat button square no radius no gradient
        MyButton::SetTemplate(MyButton::#Prop_Align, 0)
        MyButton::SetTemplate(MyButton::#Prop_Gradient, 0)
        MyButton::SetTemplate(MyButton::#Prop_Radius, 0)
        MyButton::SetTemplate(MyButton::#Prop_Type, MyButton::#Type_Normal)
       
        ProcedureReturn MyButton::New(Gadget, X, Y, Width, Height,Text)
       
    EndProcedure
   
   
    Enumeration   
        #MenuItem_1
        #MenuItem_2
        #MenuItem_3
    EndEnumeration
   
    Define Btn1, Btn2, Btn3, Btn4, Btn5, Btn6, Btn7, mnu, gdt,img
   
    Procedure   OnClick_Btn1()
        MessageRequester("On Click","hey, i am button 1 and you pushed me!")
    EndProcedure
   
    If OpenWindow(0, 0, 0, 420, 320, "Canvas Button", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget)
        SetWindowColor(0,$FFFFFF)
       
       
       
        mnu = CreatePopupMenu(#PB_Any)
        If mnu
            MenuItem(#MenuItem_1, "Item 1")
            MenuItem(#MenuItem_2, "Item 2")
            MenuItem(#MenuItem_3, "Item 3")
        EndIf
       
        Btn1 = MyButton::New(#PB_Any, 10, 10, 200, 30,"Button 1", "normal button")
        Btn2 = MyButton_Checkbox(#PB_Any, 10, 50, 220, 60,"BIG Checkbox")
        Btn3 = MyButton_Option(#PB_Any, 10,120, 200, 30,"Option Disabled")
        Btn4 = MyButton_Toggle(#PB_Any, 10,160, 220, 30,"Radio text right aligned")
        Btn5 = MyButton_Toggle(#PB_Any, 10,200, 200, 30,"Toggle ...")
        Btn6 = MyButton_Dropdown(#PB_Any, 10,240, 200, 30, mnu,"Drop down...")
       
        MyButton::SetTemplate(MyButton::#Prop_BackColor, $AA9C83)
        MyButton::SetTemplate(MyButton::#Prop_Radius, 0)
        MyButton::SetTemplate(MyButton::#Prop_BorderColor, -1)
        Btn7 = MyButton::New(#PB_Any, 10,280, 220, 30, "")
       
        MyButton::SetProperty(Btn1, MyButton::#Prop_Radius,15)
        ; attaching a pocedure to OnClick event
        MyButton::SetProperty(Btn1, MyButton::#Prop_OnClick, @OnClick_Btn1())
       
        MyButton::SetProperty(Btn2, MyButton::#Prop_BorderColor, RGB(0, 0, 255))
        MyButton::SetProperty(Btn2, MyButton::#Prop_BackColor, RGB(84, 227, 209))
        MyButton::SetProperty(Btn2, MyButton::#Prop_Align, #PB_Text_Center)
        MyButton::SetProperty(Btn2, MyButton::#Prop_Font, LoadFont(#PB_Any, "Verdana", 14, #PB_Font_Bold))
       
        MyButton::Enable(Btn3, #False)
        MyButton::SetProperty(Btn3, MyButton::#Prop_Checked, #True)
       
        MyButton::SetProperty(Btn4, MyButton::#Prop_Type, MyButton::#Type_Radio)    ; changing the type later on ...
        MyButton::SetProperty(Btn4, MyButton::#Prop_Checked, #True)
        MyButton::SetProperty(Btn4, MyButton::#Prop_Align, #PB_Text_Right)
        MyButton::SetProperty(Btn4, MyButton::#Prop_TextColor, $FFFFFF)
        MyButton::SetProperty(Btn4, MyButton::#Prop_Gradient,90)
       
        MyButton::SetProperty(Btn6, MyButton::#Prop_BackColor, $9AD968)
        MyButton::SetProperty(Btn6, MyButton::#Prop_BorderColor, $72C431)
        MyButton::SetProperty(Btn6, MyButton::#Prop_Radius, 0)
       
        img = LoadImage(#PB_Any, #PB_Compiler_Home + "examples/3d/Data/PureBasic3DLogo.png")
        MyButton::SetProperty(Btn7, MyButton::#Prop_Type, MyButton::#Type_Normal)
        MyButton::SetProperty(Btn7, MyButton::#Prop_Image, img)
        MyButton::SetProperty(Btn7, MyButton::#Prop_ImageFit, #True)
       
        Repeat
            Select WaitWindowEvent()
                Case #PB_Event_SizeWindow
                    MyButton::Resize(btn2, #PB_Ignore,#PB_Ignore, WindowWidth(0) - 220, #PB_Ignore)
                    MyButton::Resize(btn4, #PB_Ignore,#PB_Ignore, WindowWidth(0) - 220, #PB_Ignore)
                    MyButton::Resize(btn7, #PB_Ignore,#PB_Ignore, WindowWidth(0) - 220, #PB_Ignore)
                Case #PB_Event_Menu
                    Select EventMenu()
                        Case #MenuItem_1 : Debug " menuitem 1"
                        Case #MenuItem_2 : Debug " menuitem 2"
                        Case #MenuItem_3 : Debug " menuitem 3"
                    EndSelect
                   
                Case #PB_Event_CloseWindow
                    End
            EndSelect
        ForEver
       
    EndIf
   
CompilerEndIf
; IDE Options = PureBasic 5.61 (Windows - x86)
; CursorPosition = 6
; Folding = ------
; EnableXP