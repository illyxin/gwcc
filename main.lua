--[[
    gw.cc | All-in-One + ESP v5
    Stage 1 Fix: Window/Vault ESP using BoxHandleAdornment + structural scanning
--]]

local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local GuiService=game:GetService("GuiService")
local CollectionService=game:GetService("CollectionService")

local LocalPlayer=Players.LocalPlayer
local IS_TOUCH=UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local uiParent; pcall(function()uiParent=gethui()end); uiParent=uiParent or LocalPlayer:WaitForChild("PlayerGui")

local MOTION={speed=1.0,reduce=false,blur=true,dim=true,shimmer=true,idleFloat=true,edgeSnap=true}

local C={Panel=Color3.fromRGB(13,13,18),PanelLt=Color3.fromRGB(17,17,24),HdrTop=Color3.fromRGB(19,19,26),NavCol=Color3.fromRGB(15,15,20),NavAct=Color3.fromRGB(26,26,36),NavIna=Color3.fromRGB(20,20,26),NavHov=Color3.fromRGB(22,22,30),TxtPri=Color3.fromRGB(228,228,232),TxtMut=Color3.fromRGB(106,106,120),TxtBrt=Color3.fromRGB(145,145,160),TxtHint=Color3.fromRGB(74,74,85),Accent=Color3.fromRGB(90,90,122),AccentH=Color3.fromRGB(140,140,190),BarBg=Color3.fromRGB(24,24,32),BarA=Color3.fromRGB(74,74,106),BarB=Color3.fromRGB(106,106,138),BarDone=Color3.fromRGB(130,130,175),ScrClr=Color3.fromRGB(42,42,53),MinA=Color3.fromRGB(26,26,36),MinB=Color3.fromRGB(20,20,26),MinP=Color3.fromRGB(30,30,40),StrkClr=Color3.fromRGB(26,26,34),StrkAct=Color3.fromRGB(58,58,82),HLne=Color3.fromRGB(23,23,31),MinStrk=Color3.fromRGB(34,34,44)}

local ES,ED=Enum.EasingStyle,Enum.EasingDirection
local FONT=Enum.Font.Code

local function ti(dur,style,dir) return TweenInfo.new(math.max(dur*MOTION.speed*(MOTION.reduce and 0.55 or 1),0.01),style or ES.Quint,dir or ED.Out) end
local E={micro=function()return ti(0.14,ES.Quad,ED.Out)end,snap=function()return ti(0.22,ES.Quint,ED.Out)end,smooth=function()return ti(0.34,ES.Quint,ED.Out)end,slow=function()return ti(0.52,ES.Quint,ED.Out)end,exit=function()return ti(0.20,ES.Quint,ED.In)end,soft=function()return ti(0.40,ES.Sine,ED.InOut)end}

local Motion={}
Motion._reg=setmetatable({},{__mode="k"})
function Motion.to(obj,group,info,props) if not obj then return end local r=Motion._reg[obj] if not r then r={};Motion._reg[obj]=r end if r[group] then r[group]:Cancel() end local t=TweenService:Create(obj,info,props) r[group]=t t:Play() return t end
function Motion.kill(obj,group) local r=Motion._reg[obj] if r and r[group] then r[group]:Cancel() r[group]=nil end end
local springPool,springConn={},nil
function Motion.spring(scaleObj,target,opts) if not scaleObj then return end opts=opts or {} if MOTION.reduce then Motion.to(scaleObj,"scale",E.snap(),{Scale=target}) return end local st=springPool[scaleObj] if st then st.target=target if opts.stiffness then st.stiffness=opts.stiffness end if opts.damping then st.damping=opts.damping end if opts.impulse then st.vel=st.vel+opts.impulse end else springPool[scaleObj]={target=target,vel=opts.impulse or 0,stiffness=opts.stiffness or 260,damping=opts.damping or 22} end if not springConn then springConn=RunService.RenderStepped:Connect(function(dt) dt=math.min(dt,1/30) local alive=0 for obj,st in pairs(springPool) do if not obj.Parent then springPool[obj]=nil else local x=obj.Scale local a=(st.target-x)*st.stiffness-st.vel*st.damping st.vel=st.vel+a*dt obj.Scale=x+st.vel*dt if math.abs(st.target-obj.Scale)<0.0015 and math.abs(st.vel)<0.02 then obj.Scale=st.target springPool[obj]=nil else alive=alive+1 end end end if alive==0 then springConn:Disconnect() springConn=nil end end) end end
function Motion.press(scaleObj,depth) if not scaleObj then return end scaleObj.Scale=1-(depth or 0.16) Motion.spring(scaleObj,1,{stiffness=320,damping=18}) end
function Motion.stagger(list,step,startAt,fn) if MOTION.reduce then for i,v in ipairs(list) do fn(v,i) end return end for i,v in ipairs(list) do task.delay((startAt or 0)+(i-1)*step,function()fn(v,i)end) end end

local function new(class,props,parent) local i=Instance.new(class) for k,v in pairs(props) do i[k]=v end if parent then i.Parent=parent end return i end
local function corner(parent,r) new("UICorner",{CornerRadius=UDim.new(0,r)},parent) end
local function dropShadow(parent,spread,alpha) return new("ImageLabel",{Name="Shadow",BackgroundTransparency=1,Image="rbxassetid://6014261993",ImageColor3=Color3.new(0,0,0),ImageTransparency=alpha or 0.5,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(49,49,450,450),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(1,spread or 60,1,spread or 60),ZIndex=0},parent) end
local function borderStroke(parent,color,thick,transp) return new("UIStroke",{Color=color or C.StrkClr,Thickness=thick or 1,Transparency=transp or 0.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},parent) end
local function addScale(parent,v) return new("UIScale",{Scale=v or 1},parent) end
local function snapshot(root) local snap,all={},root:GetDescendants() table.insert(all,1,root) for _,o in ipairs(all) do if o:IsA("GuiObject") then snap[#snap+1]={o,"BackgroundTransparency",o.BackgroundTransparency} end if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then snap[#snap+1]={o,"TextTransparency",o.TextTransparency} elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then snap[#snap+1]={o,"ImageTransparency",o.ImageTransparency} elseif o:IsA("UIStroke") then snap[#snap+1]={o,"Transparency",o.Transparency} end end return snap end
local function fadeSnapshot(snap,info,toHidden) for _,e in ipairs(snap) do if e[1] and e[1].Parent then Motion.to(e[1],"fade_"..e[2],info,{[e[2]]=toHidden and 1 or e[3]}) end end end

local cam=workspace.CurrentCamera
local function vpSize() return (cam and cam.ViewportSize) or Vector2.new(1280,720) end
local viewport=vpSize()
local screenW,screenH=viewport.X,viewport.Y
local small=screenW<500
local PW=small and math.clamp(math.floor(screenW*0.80),260,420) or 460
local PH=small and math.clamp(math.floor(screenH*0.55),260,380) or 400
local NW,NB,HH=small and 48 or 50,small and 48 or 50,42
local NF=small and 17 or 16
local WW=small and math.clamp(math.floor(screenW*0.82),260,340) or 340

local gui=new("ScreenGui",{Name="gwcc_UI",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=9999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},uiParent)
task.spawn(function() while task.wait(1) do if not gui.Parent then gui.Parent=uiParent end if not gui.Enabled then gui.Enabled=true end end end)
local dim=new("Frame",{Name="Dim",BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderSizePixel=0,Active=false,Size=UDim2.fromScale(1,1),ZIndex=5},gui)
local blur; if MOTION.blur then pcall(function() blur=new("BlurEffect",{Name="gwcc_Blur",Size=0,Enabled=true},Lighting) end) end
local function setBackdrop(on) if MOTION.dim then Motion.to(dim,"bg",E.smooth(),{BackgroundTransparency=on and 0.45 or 1}) end if blur then Motion.to(blur,"blur",E.smooth(),{Size=on and 14 or 0}) end end

local welcomeTargetPos=UDim2.fromScale(0.5,0.5)
local welcome=new("Frame",{Name="Welcome",AnchorPoint=Vector2.new(0.5,0.5),Position=welcomeTargetPos+UDim2.fromOffset(0,34),Size=UDim2.fromOffset(WW,170),BackgroundColor3=C.Panel,BorderSizePixel=0,Rotation=1.5,ZIndex=50},gui)
corner(welcome,10) local wShadow=dropShadow(welcome,50,0.85) borderStroke(welcome,C.StrkClr,1,0.3) local welcomeScale=addScale(welcome,0.82)
local wTitle=new("TextLabel",{Name="Title",BackgroundTransparency=1,Text="Welcome to gw.cc",TextColor3=C.TxtPri,TextTransparency=1,TextXAlignment=Enum.TextXAlignment.Center,Font=FONT,TextSize=18,Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,0,28),ZIndex=1},welcome)
local wCredit=new("TextLabel",{Name="Credit",BackgroundTransparency=1,Text="by illyxin",TextColor3=C.TxtMut,TextTransparency=1,TextXAlignment=Enum.TextXAlignment.Center,Font=FONT,TextSize=12,Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,56),ZIndex=1},welcome)
local barBack=new("Frame",{Name="BarBack",BackgroundColor3=C.BarBg,BackgroundTransparency=1,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,84),Size=UDim2.new(0,WW-60,0,6),ClipsDescendants=true,ZIndex=1},welcome) corner(barBack,3)
local barFill=new("Frame",{Name="BarFill",BackgroundColor3=C.BarA,BorderSizePixel=0,Size=UDim2.new(0,0,1,0),ZIndex=2},barBack) corner(barFill,3) new("UIGradient",{Color=ColorSequence.new(C.BarA,C.BarB),Rotation=0},barFill)
local shimmer=new("Frame",{Name="Shimmer",BackgroundColor3=Color3.fromRGB(200,200,235),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(0,70,1,0),Position=UDim2.new(0,-70,0,0),ZIndex=3},barBack) new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0.55),NumberSequenceKeypoint.new(1,1)})},shimmer)
local wPct=new("TextLabel",{Name="Percent",BackgroundTransparency=1,Text="Loading... 0%",TextColor3=C.TxtBrt,TextTransparency=1,TextXAlignment=Enum.TextXAlignment.Center,Font=FONT,TextSize=11,Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,102),ZIndex=1},welcome) local pctScale=addScale(wPct,1)

local panelTargetPos=UDim2.fromScale(0.5,0.5)
local panel=new("Frame",{Name="MainMenu",AnchorPoint=Vector2.new(0.5,0.5),Position=panelTargetPos+UDim2.fromOffset(0,44),Size=UDim2.fromOffset(PW,PH),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,Rotation=1.5,ZIndex=10},gui)
corner(panel,10) local pShadow=dropShadow(panel,70,0.85) local pStroke=borderStroke(panel,C.StrkClr,1,0.3) local panelScale=addScale(panel,0.84)
local header=new("Frame",{Name="Header",BackgroundColor3=C.PanelLt,BorderSizePixel=0,Size=UDim2.new(1,0,0,HH),ZIndex=1},panel) corner(header,10) new("UIGradient",{Color=ColorSequence.new(C.HdrTop,C.Panel),Rotation=90},header)
new("Frame",{Name="HFoot",BackgroundColor3=C.Panel,BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,8),ZIndex=1},header)
new("Frame",{Name="HLine",BackgroundColor3=C.HLne,BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),ZIndex=2},header)
local brand=new("TextLabel",{Name="Brand",BackgroundTransparency=1,Text="gw.cc",TextColor3=C.TxtPri,TextXAlignment=Enum.TextXAlignment.Left,Font=FONT,TextSize=15,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,14,0.5,0),Size=UDim2.new(0,100,1,0),ZIndex=3},header)
local hint=new("TextLabel",{Name="Hint",BackgroundTransparency=1,Text=IS_TOUCH and "tap the tab to toggle" or "RightShift to toggle",TextColor3=C.TxtHint,TextXAlignment=Enum.TextXAlignment.Right,Font=FONT,TextSize=10,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-14,0.5,0),Size=UDim2.new(0,160,1,0),ZIndex=3},header)
local body=new("Frame",{Name="Body",BackgroundTransparency=1,Position=UDim2.new(0,0,0,HH),Size=UDim2.new(1,0,1,-HH),ClipsDescendants=true,ZIndex=1},panel)
local nav=new("Frame",{Name="Nav",BackgroundColor3=C.NavCol,BorderSizePixel=0,Size=UDim2.new(0,NW,1,0),ZIndex=1},body) corner(nav,10)
new("Frame",{Name="NavTopFill",BackgroundColor3=C.NavCol,BorderSizePixel=0,Size=UDim2.new(1,0,0,8),ZIndex=1},nav)

local TABS={"M","V","C"}
local TAB_NAMES={M="Main",V="",C="Config/Settings"}
local navBtns,navAccs,navScales,navGlow={},{},{},{}
for i,id in ipairs(TABS) do
local btn=new("TextButton",{Name="Nav_"..id,AutoButtonColor=false,BackgroundColor3=C.NavIna,BorderSizePixel=0,Text=id,TextColor3=C.TxtMut,Font=FONT,TextSize=NF,Position=UDim2.new(0,0,0,8+(i-1)*NB),Size=UDim2.new(1,0,0,NB),ZIndex=2},nav) corner(btn,6)
local acc=new("Frame",{Name="Accent",BackgroundColor3=C.Accent,BackgroundTransparency=1,BorderSizePixel=0,AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(0,3,0,0),ZIndex=3},btn) corner(acc,2)
navBtns[id],navAccs[id],navScales[id]=btn,acc,addScale(btn,1)
end
new("Frame",{Name="NavSep",BackgroundColor3=C.HLne,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.new(0,1,1,0),ZIndex=2},nav)

local function startGlow(id) if navGlow[id] then return end local acc=navAccs[id] if not acc or MOTION.reduce then return end navGlow[id]=TweenService:Create(acc,TweenInfo.new(1.7,ES.Sine,ED.InOut,-1,true),{BackgroundColor3=C.AccentH}) navGlow[id]:Play() end
local function stopGlow(id) if navGlow[id] then navGlow[id]:Cancel() navGlow[id]=nil if navAccs[id] then navAccs[id].BackgroundColor3=C.Accent end end end
local function styleNav(id,active) local btn,acc,scl=navBtns[id],navAccs[id],navScales[id] if not btn then return end Motion.to(btn,"color",E.snap(),{BackgroundColor3=active and C.NavAct or C.NavIna,TextColor3=active and C.TxtPri or C.TxtMut}) stopGlow(id) if active then Motion.kill(acc,"glow") local grow=Motion.to(acc,"acc",ti(0.3,ES.Quint,ED.Out),{BackgroundTransparency=0,Size=UDim2.new(0,3,1,-16)}) Motion.spring(scl,1,{impulse=0.85,stiffness=300,damping=17}) if grow and not MOTION.reduce then grow.Completed:Once(function()startGlow(id)end) end else Motion.to(acc,"acc",E.exit(),{BackgroundTransparency=1,Size=UDim2.new(0,3,0,0)}) Motion.spring(scl,1) end end

local content=new("Frame",{Name="Content",BackgroundColor3=C.Panel,BorderSizePixel=0,Position=UDim2.new(0,NW,0,0),Size=UDim2.new(1,-NW,1,0),ClipsDescendants=true,ZIndex=1},body) corner(content,10)
local function mkContentLabel() return new("TextLabel",{BackgroundTransparency=1,Text="",TextColor3=C.TxtPri,TextTransparency=1,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,Font=FONT,TextSize=18,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.new(1,-20,0,30),ZIndex=2},content) end
local labelA,labelB=mkContentLabel(),mkContentLabel()
local frontLabel,backLabel=labelA,labelB
local function crossfadeContent(text,size) local outgoing,incoming=frontLabel,backLabel frontLabel,backLabel=incoming,outgoing incoming.Text=text incoming.TextSize=size or 15 incoming.TextTransparency=1 incoming.Position=UDim2.new(0.5,0,0.5,14) incoming.ZIndex=3 outgoing.ZIndex=2 Motion.to(outgoing,"fade",ti(0.2,ES.Quint,ED.In),{TextTransparency=1,Position=UDim2.new(0.5,0,0.5,-14)}) Motion.to(incoming,"fade",ti(0.3,ES.Back,ED.Out),{TextTransparency=0,Position=UDim2.fromScale(0.5,0.5)}) end

local activeTab="M"
local firstLoad=true
local firstShow=true
local typing=false
local menuVisible=false
local typeIntro
local _visualContainer

local FAB=44
local fabPos=Vector2.new(20+FAB/2,screenH*0.5)
local minBtn=new("ImageButton",{Name="Minimize",AutoButtonColor=false,BackgroundColor3=C.MinA,BorderSizePixel=0,Image="",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(fabPos.X,fabPos.Y),Size=UDim2.fromOffset(FAB,FAB),ZIndex=30},gui)
corner(minBtn,12) dropShadow(minBtn,34,0.6) new("UIGradient",{Color=ColorSequence.new(C.MinA,C.MinB),Rotation=90},minBtn) borderStroke(minBtn,C.MinStrk,1,0.4) local minScale=addScale(minBtn,0)
local icon1=new("Frame",{Name="Icon1",BackgroundColor3=C.TxtMut,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,-4),Size=UDim2.fromOffset(18,2),ZIndex=1},minBtn) corner(icon1,1)
local icon2=new("Frame",{Name="Icon2",BackgroundColor3=C.TxtMut,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,4),Size=UDim2.fromOffset(12,2),ZIndex=1},minBtn) corner(icon2,1)
local function morphIcon(open) local info=ti(0.34,ES.Back,ED.Out) if open then Motion.to(icon1,"morph",info,{Rotation=45,Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.fromOffset(17,2),BackgroundColor3=C.AccentH}) Motion.to(icon2,"morph",info,{Rotation=-45,Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.fromOffset(17,2),BackgroundColor3=C.AccentH}) else Motion.to(icon1,"morph",info,{Rotation=0,Position=UDim2.new(0.5,0,0.5,-4),Size=UDim2.fromOffset(18,2),BackgroundColor3=C.TxtMut}) Motion.to(icon2,"morph",info,{Rotation=0,Position=UDim2.new(0.5,0,0.5,4),Size=UDim2.fromOffset(12,2),BackgroundColor3=C.TxtMut}) end end
local idleFloat
local function startIdle() if not MOTION.idleFloat or MOTION.reduce or idleFloat then return end idleFloat=TweenService:Create(minBtn,TweenInfo.new(2.4,ES.Sine,ED.InOut,-1,true),{Rotation=2.5}) idleFloat:Play() end
local function stopIdle() if idleFloat then idleFloat:Cancel() idleFloat=nil end Motion.to(minBtn,"rot",E.snap(),{Rotation=0}) end

local function showPanelAnimated()
panel.Visible=true menuVisible=true setBackdrop(true) morphIcon(true)
if _visualContainer then _visualContainer.Visible=false end
Motion.to(pShadow,"fade",E.slow(),{ImageTransparency=0.5}) Motion.to(pStroke,"stroke",E.smooth(),{Color=C.StrkAct,Transparency=0.15})
if firstShow then
firstShow=false panelScale.Scale=0.84 panel.Position=panelTargetPos+UDim2.fromOffset(0,44) panel.Rotation=1.5
Motion.spring(panelScale,1,{stiffness=190,damping=17}) Motion.to(panel,"pos",ti(0.5,ES.Quint,ED.Out),{Position=panelTargetPos}) Motion.to(panel,"rot",ti(0.6,ES.Quint,ED.Out),{Rotation=0})
header.Position=UDim2.new(0,0,0,-HH) Motion.to(header,"pos",ti(0.45,ES.Quint,ED.Out),{Position=UDim2.new(0,0,0,0)})
brand.TextTransparency,hint.TextTransparency=1,1
task.delay(0.18,function() Motion.to(brand,"fade",E.smooth(),{TextTransparency=0}) Motion.to(hint,"fade",E.smooth(),{TextTransparency=0}) end)
for _,id in ipairs(TABS) do navScales[id].Scale=0 navBtns[id].TextTransparency=1 end
Motion.stagger(TABS,0.04,0.08,function(id) Motion.spring(navScales[id],1,{stiffness=280,damping=14}) Motion.to(navBtns[id],"fade",ti(0.20,ES.Quint,ED.Out),{TextTransparency=0}) end)
task.delay(MOTION.reduce and 0.15 or 0.25,function()styleNav("M",true)end)
task.delay(MOTION.reduce and 0.25 or 0.5,function()if firstLoad then typeIntro() end end)
else
panelScale.Scale=0.9 panel.Position=panelTargetPos+UDim2.fromOffset(0,26)
Motion.spring(panelScale,1,{stiffness=260,damping=18}) Motion.to(panel,"pos",E.smooth(),{Position=panelTargetPos}) Motion.to(panel,"rot",E.smooth(),{Rotation=0})
Motion.spring(navScales[activeTab],1,{impulse=0.5})
task.delay(0.15,function()if menuVisible then startGlow(activeTab) end end)
end
task.spawn(function() while menuVisible and panelScale and panelScale.Parent do if panelScale.Scale>0.985 then break end task.wait(0.02) end if menuVisible and _visualContainer and activeTab=="V" then _visualContainer.Visible=true end end)
end

local function hidePanelAnimated()
if _visualContainer then _visualContainer.Visible=false end
menuVisible=false setBackdrop(false) morphIcon(false)
for id,_ in pairs(navGlow) do stopGlow(id) end
Motion.to(pShadow,"fade",E.exit(),{ImageTransparency=0.9}) Motion.to(pStroke,"stroke",E.exit(),{Color=C.StrkClr,Transparency=0.3})
Motion.to(panelScale,"scale",ti(0.22,ES.Quint,ED.In),{Scale=0.9}) Motion.to(panel,"pos",ti(0.22,ES.Quint,ED.In),{Position=panelTargetPos+UDim2.fromOffset(0,22)}) Motion.to(panel,"rot",ti(0.22,ES.Quint,ED.In),{Rotation=-1})
task.delay(0.22*MOTION.speed,function()if not menuVisible then panel.Visible=false end end)
end

local function toggleMenu() if menuVisible then hidePanelAnimated() else showPanelAnimated() end end

for _,id in ipairs(TABS) do
local btn,scl=navBtns[id],navScales[id]
if not IS_TOUCH then
btn.MouseEnter:Connect(function() if activeTab~=id then Motion.to(btn,"color",E.micro(),{BackgroundColor3=C.NavHov}) Motion.spring(scl,1.05,{stiffness=300,damping=24}) end end)
btn.MouseLeave:Connect(function() if activeTab~=id then Motion.to(btn,"color",E.micro(),{BackgroundColor3=C.NavIna}) Motion.spring(scl,1,{stiffness=300,damping=24}) end end)
end
btn.MouseButton1Click:Connect(function()
Motion.press(scl,0.18)
if activeTab==id and not firstLoad then return end
local prev=activeTab activeTab=id firstLoad=false typing=false
if prev~=id then styleNav(prev,false) end styleNav(id,true)
crossfadeContent(TAB_NAMES[id],15)
end)
end

local dragging,dragStart,startPos=false,nil,nil
local minDragging,minDragStart,minStartPos,minMoved=false,nil,nil,false
local minVel,lastMinPos,lastMinT=Vector2.zero,Vector2.zero,0
local function startDrag(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true dragStart=input.Position startPos=panel.Position Motion.spring(panelScale,1.015,{stiffness=260,damping:26}) Motion.to(pShadow,"drag",E.smooth(),{ImageTransparency=0.35}) end end
panel.InputBegan:Connect(startDrag) header.InputBegan:Connect(startDrag) body.InputBegan:Connect(startDrag) nav.InputBegan:Connect(startDrag) content.InputBegan:Connect(startDrag)
minBtn.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then minDragging=true minMoved=false minDragStart=input.Position minStartPos=fabPos minVel=Vector2.zero lastMinPos=Vector2.new(input.Position.X,input.Position.Y) lastMinT=os.clock() stopIdle() Motion.press(minScale,0.16) Motion.to(minBtn,"color",E.micro(),{BackgroundColor3=C.MinP}) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end if dragging then dragging=false Motion.spring(panelScale,1,{stiffness=240,damping=20}) Motion.to(pShadow,"drag",E.smooth(),{ImageTransparency=menuVisible and 0.5 or 0.9}) end if minDragging then minDragging=false Motion.to(minBtn,"color",E.micro(),{BackgroundColor3=C.MinA}) if not minMoved then toggleMenu() Motion.spring(minScale,1,{impulse=1.1}) else local vp=vpSize() local pad=FAB/2+14 local projected=fabPos+minVel*0.12 local targetX=projected.X if MOTION.edgeSnap then targetX=(projected.X<vp.X*0.5) and pad or (vp.X-pad) end local targetY=math.clamp(projected.Y,pad,vp.Y-pad) fabPos=Vector2.new(targetX,targetY) Motion.to(minBtn,"pos",ti(0.45,ES.Back,ED.Out),{Position=UDim2.fromOffset(fabPos.X,fabPos.Y)}) end startIdle() end end)
UserInputService.InputChanged:Connect(function(input) if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end if dragging and dragStart then local d=input.Position-dragStart panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) panelTargetPos=panel.Position end if minDragging and minDragStart then local d=input.Position-minDragStart if d.Magnitude>6 then minMoved=true end local now=os.clock() local dt2=math.max(now-lastMinT,1/240) local cur=Vector2.new(input.Position.X,input.Position.Y) minVel=(cur-lastMinPos)/dt2 lastMinPos,lastMinT=cur,now local vp=vpSize() local pad=FAB/2+4 fabPos=Vector2.new(math.clamp(minStartPos.X+d.X,pad,vp.X-pad),math.clamp(minStartPos.Y+d.Y,pad,vp.Y-pad)) Motion.kill(minBtn,"pos") minBtn.Position=UDim2.fromOffset(fabPos.X,fabPos.Y) end end)
UserInputService.InputBegan:Connect(function(input,processed) if processed then return end if input.KeyCode==Enum.KeyCode.RightShift then toggleMenu() end end)

function typeIntro()
typing=true frontLabel.Text="" frontLabel.TextSize=18 frontLabel.TextTransparency=0 frontLabel.Position=UDim2.fromScale(0.5,0.5) backLabel.TextTransparency=1
local raw=LocalPlayer.DisplayName if not raw or raw=="" then raw=LocalPlayer.Name end raw=tostring(raw):gsub("[^%w%s_%.%-]","")
local full,built="Welcome, "..raw.."!",""
for i=1,#full do
if not typing then return end
local ch=full:sub(i,i)
built=built..ch
frontLabel.Text=built.."_"
local w=0.08
if ch==" " then w=0.04
elseif ch=="," then w=0.2
elseif ch=="!" then w=0.25 end
task.wait(w*MOTION.speed)
end
if not typing then frontLabel.Text=full return end
frontLabel.Text=full.."_"
task.wait(0.3)
frontLabel.Text=full
typing=false
end

local function tweenBar(target,dur) Motion.to(barFill,"size",ti(dur,ES.Quint,ED.Out),{Size=UDim2.new(target,0,1,0)}) task.wait(dur*MOTION.speed) end
task.spawn(function()
local conns={}
local ok,err=pcall(function()
Motion.spring(welcomeScale,1,{stiffness=190,damping=17}) Motion.to(welcome,"pos",ti(0.5,ES.Quint,ED.Out),{Position=welcomeTargetPos}) Motion.to(welcome,"rot",ti(0.6,ES.Quint,ED.Out),{Rotation=0}) Motion.to(wShadow,"fade",E.slow(),{ImageTransparency=0.5})
Motion.stagger({wTitle,wCredit,barBack,wPct},0.08,0.12,function(obj) if obj==barBack then Motion.to(obj,"fade",E.smooth(),{BackgroundTransparency=0}) else Motion.to(obj,"fade",E.smooth(),{TextTransparency=0}) end if obj.Parent and obj:IsA("TextLabel") then obj.Position=obj.Position+UDim2.fromOffset(0,6) Motion.to(obj,"pos",E.smooth(),{Position=obj.Position-UDim2.fromOffset(0,6)}) end end)
local shown=0
conns[#conns+1]=RunService.RenderStepped:Connect(function(dt) local actual=barFill.Size.X.Scale shown=shown+(actual-shown)*math.min(dt*9,1) wPct.Text=string.format("Loading... %d%%",math.floor(shown*100+0.5)) wPct.TextColor3=C.TxtBrt:Lerp(C.BarDone,shown) if MOTION.shimmer and not MOTION.reduce then shimmer.BackgroundTransparency=(actual>0.02) and 0 or 1 end end)
if MOTION.shimmer and not MOTION.reduce then task.spawn(function() while shimmer.Parent do local w=barBack.AbsoluteSize.X shimmer.Position=UDim2.new(0,-70,0,0) Motion.to(shimmer,"sweep",TweenInfo.new(1.1,ES.Sine,ED.InOut),{Position=UDim2.new(0,(w>0 and w or WW-60)+10,0,0)}) task.wait(1.5) end end) end
tweenBar(0.15,0.8) task.wait(0.4*MOTION.speed) tweenBar(0.35,0.7) task.wait(0.5*MOTION.speed) tweenBar(0.55,0.8) task.wait(0.4*MOTION.speed) tweenBar(0.75,0.6) task.wait(0.5*MOTION.speed) tweenBar(0.90,0.5) task.wait(0.4*MOTION.speed) tweenBar(1.00,0.4)
Motion.to(barFill,"color",E.snap(),{BackgroundColor3=C.BarDone}) Motion.press(pctScale,-0.12) task.wait(0.3*MOTION.speed)
for _,c in ipairs(conns) do c:Disconnect() end conns={}
local snap=snapshot(welcome) fadeSnapshot(snap,ti(0.35,ES.Quint,ED.In),true) Motion.to(welcomeScale,"scale",ti(0.35,ES.Quint,ED.In),{Scale=0.88}) Motion.to(welcome,"rot",ti(0.35,ES.Quint,ED.In),{Rotation=-1.5})
task.delay(0.14,function()
showPanelAnimated()
task.delay(0.4,function()
Motion.spring(minScale,1,{stiffness=240,damping=15})
task.delay(0.45,startIdle)
end)
end)
task.delay(0.5,function()if welcome then welcome:Destroy() end end)
end)
if not ok then for _,c in ipairs(conns) do c:Disconnect() end pcall(function() writefile("Error.txt",os.date().."\nBOOT: "..tostring(err).."\n"..debug.traceback()) end) warn("[gw.cc] Boot: "..tostring(err)) end
end)

gui.Destroying:Connect(function() stopIdle() for id,_ in pairs(navGlow) do stopGlow(id) end if springConn then springConn:Disconnect() end if blur then pcall(function() blur:Destroy() end) end end)

local UI={gui=gui,panel=panel,body=body,nav=nav,content=content,header=header,Motion=Motion,C=C,E=E,ES=ES,ED=ED,ti=ti,new=new,corner=corner,dropShadow=dropShadow,borderStroke=borderStroke,addScale=addScale,TABS=TABS,TAB_NAMES=TAB_NAMES,navBtns=navBtns,navScales=navScales,styleNav=styleNav,startGlow=startGlow,stopGlow=stopGlow,crossfadeContent=crossfadeContent,frontLabel=frontLabel,backLabel=backLabel,toggleMenu=toggleMenu,small=small,PW=PW,PH=PH,NW=NW,NB=NB,HH=HH,NF=NF,vpSize=vpSize,LocalPlayer=LocalPlayer}

local mto=Motion.to local mkill=Motion.kill local mspring=Motion.spring local mpress=Motion.press local mstagger=Motion.stagger
local TS=TweenService local GuiSvc=GuiService local UIS=UserInputService local TOUCH=IS_TOUCH
local function cti(d,style,dir) local st=Enum.EasingStyle[style] or ES.Quint local dr=Enum.EasingDirection[dir] or ED.Out return ti(d,st,dr) end
local function cmicro() return E.micro() end

local TRK_OFF=Color3.fromRGB(28,28,38) local TRK_ON=Color3.fromRGB(60,60,90) local TRK_EDGE=Color3.fromRGB(34,34,44)
local KNB_OFF=Color3.fromRGB(180,180,195) local KNB_ON=Color3.fromRGB(228,228,232) local KNOB_L,KNOB_R=11,29
local SQ_EDGE=Color3.fromRGB(40,40,50) local TRACK_BG=Color3.fromRGB(24,24,32)
local DEFAULT_COLORS={killer=Color3.fromRGB(255,0,0),survivor=Color3.fromRGB(0,100,255),pallet=Color3.fromRGB(255,165,0),window=Color3.fromRGB(255,255,255),generator=Color3.fromRGB(255,255,0),hook=Color3.fromRGB(139,69,19),zombie=Color3.fromRGB(128,0,128)}
local Settings={esp={killer={enabled=false,name=false,distance=false,outline={enabled=true,color=DEFAULT_COLORS.killer},fill={enabled=false,color=DEFAULT_COLORS.killer}},survivor={enabled=false,name=false,distance=false,healthStatus=false,outline={enabled=true,color=DEFAULT_COLORS.survivor},fill={enabled=false,color=DEFAULT_COLORS.survivor},healthHealthy={enabled=true,color=Color3.fromRGB(0,255,0)},healthInjured={enabled=true,color=Color3.fromRGB(255,0,0)}},pallet={enabled=false,name=false,distance=false,outline={enabled=true,color=DEFAULT_COLORS.pallet},fill={enabled=false,color=DEFAULT_COLORS.pallet}},window={enabled=false,name=false,distance=false,outline={enabled=true,color=DEFAULT_COLORS.window},fill={enabled=false,color=DEFAULT_COLORS.window}},generator={enabled=false,name=false,distance=false,progress=false,outline={enabled=true,color=DEFAULT_COLORS.generator},fill={enabled=false,color=DEFAULT_COLORS.generator}},hook={enabled=false,name=false,distance=false,outline={enabled=true,color=DEFAULT_COLORS.hook},fill={enabled=false,color=DEFAULT_COLORS.hook}},zombie={enabled=false,name=false,distance=false,outline={enabled=true,color=DEFAULT_COLORS.zombie},fill={enabled=false,color=DEFAULT_COLORS.zombie}}},render={fov=70,brightness=50,noFog=false}}

local function round(inst,r) local c=Instance.new("UICorner") c.CornerRadius=(typeof(r)=="UDim") and r or UDim.new(0,r or 6) c.Parent=inst return c end
local function edge(inst,color,thick,transp) local s=Instance.new("UIStroke") s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Color=color s.Thickness=thick or 1 s.Transparency=transp or 0 s.Parent=inst return s end
local function scaleOf(inst,v) local s=inst:FindFirstChildOfClass("UIScale") or Instance.new("UIScale") s.Scale=v or 1 s.Parent=inst return s end
local function lighten(c,a) return c:Lerp(Color3.new(1,1,1),a) end
local function screenOffset() if gui.IgnoreGuiInset then return Vector2.new(0,0) end local ins=GuiService:GetGuiInset() return Vector2.new(ins.X,ins.Y) end
local function isPointer(input) return input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch end
local function isMove(input) return input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch end

local function makeSwitch(parent,opts)
opts=opts or {} local z=opts.zIndex or 2 local pad=opts.rightPad or 14 local onToggle=opts.onToggle
local track=new("TextButton",{Name="SwitchTrack",Text="",AutoButtonColor=false,BackgroundColor3=TRK_OFF,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-pad,0.5,0),Size=UDim2.fromOffset(40,22),ZIndex=z},parent)
round(track,UDim.new(1,0)) edge(track,TRK_EDGE,1,0.4) local tsc=scaleOf(track,1)
local knob=new("Frame",{Name="Knob",BackgroundColor3=KNB_OFF,BorderSizePixel=0,Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,KNOB_L,0.5,0),ZIndex=z+1},track) round(knob,UDim.new(1,0))
local api={track=track,knob=knob,scale=tsc} local state,hovering=false,false
local function paint(animate) local bg=state and TRK_ON or TRK_OFF if hovering then bg=lighten(bg,0.08) end local kx=state and KNOB_R or KNOB_L local kcl=state and KNB_ON or KNB_OFF if animate then mto(knob,"knobX",cti(0.30,"Back","Out"),{Position=UDim2.new(0,kx,0.5,0)}) mto(knob,"knobCol",cti(0.25,"Quint","Out"),{BackgroundColor3=kcl}) mto(track,"trackBg",cti(0.25,"Quint","Out"),{BackgroundColor3=bg}) else mkill(knob,"knobX") mkill(knob,"knobCol") mkill(track,"trackBg") knob.Position=UDim2.new(0,kx,0.5,0) knob.BackgroundColor3=kcl track.BackgroundColor3=bg end end
function api.getState() return state end
function api.setState(on,animate,silent) on=on and true or false local changed=(on~=state) state=on paint(animate~=false) if changed and not silent then if onToggle then task.spawn(onToggle,state) end if api.onToggle then task.spawn(api.onToggle,state) end end return state end
track.MouseButton1Click:Connect(function() mpress(tsc,0.12) api.setState(not state,true) end)
if not TOUCH then track.MouseEnter:Connect(function() hovering=true mto(track,"trackBg",cmicro(),{BackgroundColor3=lighten(state and TRK_ON or TRK_OFF,0.08)}) end) track.MouseLeave:Connect(function() hovering=false mto(track,"trackBg",cmicro(),{BackgroundColor3=state and TRK_ON or TRK_OFF}) end) end
api.setState(opts.default,false,true) return api
end

local function createToggle(parent,name,defaultState,onToggle,textSize)
local row=new("Frame",{Name="ToggleRow_"..tostring(name),Size=UDim2.new(1,0,0,36),BackgroundTransparency=1},parent)
new("TextLabel",{Name="Label",BackgroundTransparency=1,Text=tostring(name),TextColor3=C.TxtPri,TextXAlignment=Enum.TextXAlignment.Left,Font=FONT,TextSize=textSize or 13,Position=UDim2.new(0,14,0,0),Size=UDim2.new(1,-80,1,0),ZIndex=2},row)
local sw=makeSwitch(row,{default=defaultState,onToggle=onToggle,rightPad=14,zIndex=2})
return {frame=row,switch=sw,setState=function(on,animate)return sw.setState(on,animate~=false)end,getState=sw.getState}
end

local function createAccordion(parent,name,hasToggle,defaultExpanded,textSize)
local onToggle=(type(hasToggle)=="function") and hasToggle or nil
local withToggle=onToggle~=nil or hasToggle==true
local container=new("Frame",{Name="Accordion_"..tostring(name),Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,ClipsDescendants=true},parent)
local headerF=new("Frame",{Name="Header",BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),ZIndex=2},container)
local expanded=defaultExpanded and true or false
local arrow=new("TextButton",{Name="Arrow",Text="▼",AutoButtonColor=false,BackgroundTransparency=1,TextColor3=C.TxtMut,Font=FONT,TextSize=10,Position=UDim2.new(0,8,0,0),Size=UDim2.fromOffset(20,36),Rotation=expanded and 0 or -90,ZIndex=3},headerF)
local asc=scaleOf(arrow,1)
local title=new("TextLabel",{Name="Title",BackgroundTransparency=1,Text=tostring(name),TextColor3=C.TxtPri,TextXAlignment=Enum.TextXAlignment.Left,Font=FONT,TextSize=textSize or 13,Position=UDim2.new(0,30,0,0),Size=UDim2.new(1,-80,1,0),ZIndex=3},headerF)
local sw
if withToggle then sw=makeSwitch(headerF,{default=false,onToggle=onToggle,rightPad=54,zIndex=4}) end
local contentFrame=new("Frame",{Name="Content",BackgroundTransparency=1,Position=UDim2.new(0,0,0,36),Size=UDim2.new(1,0,0,0),ClipsDescendants=true,ZIndex=2,Visible=false},container)
local layout=new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),FillDirection=Enum.FillDirection.Vertical},contentFrame)
local order=0
contentFrame.ChildAdded:Connect(function(ch) if ch:IsA("GuiObject") and ch.LayoutOrder==0 then order=order+1 ch.LayoutOrder=order end end)
local function measured() return math.max(0,layout.AbsoluteContentSize.Y+6) end
local function apply(animate)
local h=expanded and measured() or 0
if h>0 then contentFrame.Visible=true end
if animate then
local info=expanded and cti(0.30,"Back","Out") or cti(0.25,"Quint","In")
mto(contentFrame,"accH",info,{Size=UDim2.new(1,0,0,h)})
mto(container,"accH",info,{Size=UDim2.new(1,0,0,36+h)})
else
mkill(contentFrame,"accH") mkill(container,"accH")
contentFrame.Size=UDim2.new(1,0,0,h) container.Size=UDim2.new(1,0,0,36+h)
end
if not expanded then
if animate then task.delay(0.3,function() if not expanded then contentFrame.Visible=false end end)
else contentFrame.Visible=false end
end
end
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if expanded then apply(true) end end)
local acc={frame=container,content=contentFrame,header=headerF,toggle=sw}
function acc.isExpanded() return expanded end
function acc.setExpanded(on,animate) on=on and true or false expanded=on animate=animate~=false if animate then mto(arrow,"arrowRot",cti(0.28,"Back","Out"),{Rotation=on and 0 or -90}) else mkill(arrow,"arrowRot") arrow.Rotation=on and 0 or -90 end apply(animate) if on and animate then local kids={} for _,ch in ipairs(contentFrame:GetChildren()) do if ch:IsA("GuiObject") then table.insert(kids,ch) end end table.sort(kids,function(a,b)return a.LayoutOrder<b.LayoutOrder end) for _,kid in ipairs(kids) do scaleOf(kid,0.94) end mstagger(kids,0.03,0.02,function(kid) local s=kid:FindFirstChildOfClass("UIScale") if s then mspring(s,1) end end) end return expanded end
function acc.addRow(inst) order=order+1 inst.LayoutOrder=order inst.Parent=contentFrame return inst end
function acc.refresh() apply(true) end
arrow.MouseButton1Click:Connect(function() mpress(asc,0.08) acc.setExpanded(not expanded,true) end)
if not TOUCH then arrow.MouseEnter:Connect(function() mto(title,"hdrTxt",cmicro(),{TextColor3=C.AccentH}) mto(arrow,"hdrArw",cmicro(),{TextColor3=C.TxtPri}) end) arrow.MouseLeave:Connect(function() mto(title,"hdrTxt",cmicro(),{TextColor3=C.TxtPri}) mto(arrow,"hdrArw",cmicro(),{TextColor3=C.TxtMut}) end) end
apply(false) return acc
end

local activePicker=nil
local function openPicker(cfg)
if activePicker then activePicker.close() end
local small=UI.small local h,s,v=cfg.color:ToHSV() local enabled=cfg.enabled and true or false
local svH=small and 140 or 160 local pw=small and 210 or 240 local yHue=12+svH+12 local yPrev=yHue+16+12 local yEn=yPrev+28+10 local ph=yEn+30+12
local backdrop=new("Frame",{Name="ColorPickerOverlay",BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Active=true,ZIndex=100},gui)
local dismiss=new("TextButton",{Name="Dismiss",Text="",AutoButtonColor:false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=100},backdrop)
local pnl=new("Frame",{Name="PickerPanel",BackgroundColor3=C.Panel,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(pw,ph),Active=true,ZIndex=101},backdrop)
round(pnl,8) edge(pnl,C.StrkClr,1,0.15) dropShadow(pnl,30,0.55) local psc=scaleOf(pnl,0.85)
local sv=new("Frame",{Name="SV",BackgroundColor3=Color3.fromHSV(h,1,1),BorderSizePixel=0,Position=UDim2.new(0,12,0,12),Size=UDim2.new(1,-24,0,svH),ClipsDescendants=true,ZIndex=102},pnl) round(sv,6)
local white=new("Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=103},sv) round(white,6) new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})},white)
local black=new("Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=104},sv) round(black,6) new("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})},black)
local cursor=new("Frame",{BackgroundTransparency=1,Size=UDim2.fromOffset(12,12),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(s,1-v),ZIndex=105},sv) round(cursor,UDim.new(1,0)) edge(cursor,Color3.new(1,1,1),2,0.05)
local svHit=new("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=106},sv)
local hueKeys={} for i=0,6 do table.insert(hueKeys,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1))) end
local hue=new("Frame",{Name="Hue",BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Position=UDim2.new(0,12,0,yHue),Size=UDim2.new(1,-24,0,16),ZIndex=102},pnl) round(hue,4) new("UIGradient",{Color=ColorSequence.new(hueKeys)},hue)
local hueInd=new("Frame",{BackgroundColor3=Color3.fromRGB(240,240,245),BorderSizePixel=0,Size=UDim2.fromOffset(6,22),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(h,0.5),ZIndex=104},hue) round(hueInd,3) edge(hueInd,Color3.fromRGB(20,20,26),1,0.3)
local hueHit=new("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,1,12),Position=UDim2.new(0,0,0,-6),ZIndex=105},hue)
local preview=new("Frame",{BackgroundColor3=cfg.color,BorderSizePixel=0,Position=UDim2.new(0,12,0,yPrev),Size=UDim2.fromOffset(28,28),ZIndex=102},pnl) round(preview,6) edge(preview,SQ_EDGE,1,0)
local rgbText=new("TextLabel",{BackgroundTransparency=1,Font=FONT,TextSize=12,TextColor3=C.TxtMut,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.new(0,48,0,yPrev),Size=UDim2.new(1,-60,0,28),Text="",ZIndex=102},pnl)
local enRow=new("Frame",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,yEn),Size=UDim2.new(1,-24,0,30),ZIndex=102},pnl)
new("TextLabel",{BackgroundTransparency=1,Font=FONT,TextSize=12,TextColor3=C.TxtPri,TextXAlignment=Enum.TextXAlignment.Left,Text="Enabled",Size=UDim2.new(1,-50,1,0),ZIndex=103},enRow)
local conns={} local dragging2=nil local closing=false local cachedOffset=screenOffset()
local function push(smooth) local col=Color3.fromHSV(h,s,v) sv.BackgroundColor3=Color3.fromHSV(h,1,1) preview.BackgroundColor3=col rgbText.Text=string.format("R:%d G:%d B:%d",math.floor(col.R*255+0.5),math.floor(col.G*255+0.5),math.floor(col.B*255+0.5)) if smooth then mto(cursor,"svCur",cti(0.06,"Quad","Out"),{Position=UDim2.fromScale(s,1-v)}) mto(hueInd,"hueInd",cti(0.08,"Quad","Out"),{Position=UDim2.fromScale(h,0.5)}) else mkill(cursor,"svCur") mkill(hueInd,"hueInd") cursor.Position=UDim2.fromScale(s,1-v) hueInd.Position=UDim2.fromScale(h,0.5) end if cfg.apply then cfg.apply(col,enabled) end end
local enSwitch=makeSwitch(enRow,{default=enabled,rightPad=0,zIndex=103,onToggle=function(on)enabled=on push(true) end})
local function fromSV(p) local ap,as=sv.AbsolutePosition+cachedOffset,sv.AbsoluteSize s=math.clamp((p.X-ap.X)/math.max(as.X,1),0,1) v=1-math.clamp((p.Y-ap.Y)/math.max(as.Y,1),0,1) push(true) end
local function fromHue(p) local ap,as=hue.AbsolutePosition+cachedOffset,hue.AbsoluteSize h=math.clamp((p.X-ap.X)/math.max(as.X,1),0,1) push(true) end
table.insert(conns,svHit.InputBegan:Connect(function(i) if isPointer(i) then dragging2="sv" fromSV(i.Position) end end))
table.insert(conns,hueHit.InputBegan:Connect(function(i) if isPointer(i) then dragging2="hue" fromHue(i.Position) end end))
table.insert(conns,UIS.InputChanged:Connect(function(i) if not dragging2 or not isMove(i) then return end if dragging2=="sv" then fromSV(i.Position) else fromHue(i.Position) end end))
table.insert(conns,UIS.InputEnded:Connect(function(i) if isPointer(i) then dragging2=nil end end))
local api={}
function api.close() if closing then return end closing=true if activePicker==api then activePicker=nil end for _,c in ipairs(conns) do pcall(function()c:Disconnect()end) end table.clear(conns) mto(backdrop,"fade",cti(0.18,"Quint","In"),{BackgroundTransparency=1}) mto(psc,"pop",cti(0.18,"Quint","In"),{Scale=0.9}) task.delay(0.2,function()if backdrop and backdrop.Parent then backdrop:Destroy() end end) if cfg.onClose then cfg.onClose() end end
dismiss.MouseButton1Click:Connect(api.close)
push(false) mto(backdrop,"fade",cti(0.20,"Quad","Out"),{BackgroundTransparency=0.5}) mspring(psc,1) activePicker=api return api
end

local function createColorSetting(parent,name,defaultColor,defaultEnabled,onColorChange,textSize)
local color=defaultColor or Color3.fromRGB(255,255,255) local enabled=defaultEnabled and true or false
local row=new("Frame",{Name="ColorRow_"..tostring(name),Size=UDim2.new(1,0,0,36),BackgroundTransparency=1},parent)
new("TextLabel",{Name="Label",BackgroundTransparency=1,Text=tostring(name),TextColor3=C.TxtPri,TextXAlignment=Enum.TextXAlignment.Left,Font=FONT,TextSize=textSize or 12,Position=UDim2.new(0,14,0,0),Size=UDim2.new(1,-104,1,0),ZIndex=2},row)
local square=new("TextButton",{Name="ColorSquare",Text="",AutoButtonColor=false,BackgroundColor3=color,BorderSizePixel=0,Size=UDim2.fromOffset(20,20),AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-64,0.5,0),ZIndex=3},row) round(square,4) edge(square,SQ_EDGE,1,0) local ssc=scaleOf(square,1)
local cross=new("TextLabel",{Name="Off",BackgroundTransparency=1,Text="✕",Font=FONT,TextSize=12,TextColor3=C.TxtHint,Size=UDim2.fromScale(1,1),Visible=false,ZIndex=4},square)
local api={frame=row,square=square}
local function paintSquare(animate) local target=enabled and 0 or 0.55 cross.Visible=not enabled if animate then mto(square,"sqFade",cmicro(),{BackgroundTransparency=target,BackgroundColor3=color}) else mkill(square,"sqFade") square.BackgroundTransparency=target square.BackgroundColor3=color end end
local function fire() if onColorChange then task.spawn(onColorChange,color,enabled) end end
local sw=makeSwitch(row,{default=enabled,rightPad=14,zIndex=2,onToggle=function(on)enabled=on paintSquare(true) fire() end})
square.MouseButton1Click:Connect(function() mpress(ssc,0.12) openPicker({color=color,enabled=enabled,apply=function(newColor,newEnabled) color,enabled=newColor,newEnabled paintSquare(true) if sw.getState()~=enabled then sw.setState(enabled,true,true) end fire() end}) end)
if not TOUCH then square.MouseEnter:Connect(function()mspring(ssc,1.12)end) square.MouseLeave:Connect(function()mspring(ssc,1)end) end
api.getColor=function()return color end api.getEnabled=function()return enabled end api.switch=sw
function api.setColor(newColor,newEnabled) color=newColor or color if newEnabled~=nil then enabled=newEnabled and true or false sw.setState(enabled,true,true) end paintSquare(true) fire() end
paintSquare(false) return api
end

local function createSlider(parent,name,minV,maxV,default,suffix,onValueChange)
minV=minV or 0 maxV=maxV or 100 suffix=suffix or ""
local row=new("Frame",{Name="SliderRow_"..tostring(name),Size=UDim2.new(1,0,0,44),BackgroundTransparency=1},parent)
new("TextLabel",{Name="Label",BackgroundTransparency=1,Text=tostring(name),TextColor3=C.TxtPri,TextXAlignment=Enum.TextXAlignment.Left,Font=FONT,TextSize=13,Position=UDim2.new(0,14,0,0),Size=UDim2.new(0.5,0,0,20),ZIndex=2},row)
local valueTxt=new("TextLabel",{Name="Value",BackgroundTransparency=1,Text="",TextColor3=C.TxtMut,TextXAlignment=Enum.TextXAlignment.Right,Font=FONT,TextSize=12,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,0),Size=UDim2.new(0,60,0,20),ZIndex=2},row)
local track=new("Frame",{Name="Track",BackgroundColor3=TRACK_BG,BorderSizePixel=0,Position=UDim2.new(0,14,0,26),Size=UDim2.new(1,-28,0,6),ZIndex=2},row) round(track,3)
local fill=new("Frame",{Name="Fill",BackgroundColor3=C.Accent,BorderSizePixel=0,Size=UDim2.new(0,0,1,0),ZIndex=3},track) round(fill,3) new("UIGradient",{Color=ColorSequence.new(C.BarA,C.BarB)},fill)
local handle=new("Frame",{Name="Handle",BackgroundColor3=C.TxtPri,BorderSizePixel=0,Size=UDim2.fromOffset(14,14),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),ZIndex=4},track) round(handle,UDim.new(1,0)) local hsc=scaleOf(handle,1)
local hit=new("TextButton",{Name="Hit",Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.new(0,14,0,18),Size=UDim2.new(1,-28,0,22),ZIndex=5},row)
local value=math.clamp(default or minV,minV,maxV) local dragging3=false
local function quantize(x) if (maxV-minV)>=5 then return math.floor(x+0.5) end return math.floor(x*100+0.5)/100 end
local function frac() return (value-minV)/math.max(maxV-minV,1e-6) end
local function paint(animate) local f=frac() if animate then mto(fill,"sldFill",cti(0.25,"Quint","Out"),{Size=UDim2.new(f,0,1,0)}) mto(handle,"sldPos",cti(0.25,"Quint","Out"),{Position=UDim2.new(f,0,0.5,0)}) else mkill(fill,"sldFill") mkill(handle,"sldPos") fill.Size=UDim2.new(f,0,1,0) handle.Position=UDim2.new(f,0,0.5,0) end valueTxt.Text=tostring(value)..suffix end
local api={frame=row,handle=handle,track=track}
function api.setValue(newValue,animate,silent) local q=quantize(math.clamp(newValue or value,minV,maxV)) local changed=q~=value value=q paint(animate==true) if changed and not silent and onValueChange then task.spawn(onValueChange,value) end return value end
function api.getValue() return value end
function api.setRange(newMin,newMax) minV,maxV=newMin or minV,newMax or maxV api.setValue(value,true,true) end
local function fromX(px) local off=screenOffset() local ap,as=track.AbsolutePosition+off,track.AbsoluteSize local f=math.clamp((px-ap.X)/math.max(as.X,1),0,1) api.setValue(minV+f*(maxV-minV),false) end
hit.InputBegan:Connect(function(i) if not isPointer(i) then return end dragging3=true mpress(hsc,0.15) fromX(i.Position.X) end)
local moveConn=UIS.InputChanged:Connect(function(i) if dragging3 and isMove(i) then fromX(i.Position.X) end end)
local endConn=UIS.InputEnded:Connect(function(i) if dragging3 and isPointer(i) then dragging3=false mspring(hsc,(not TOUCH and api.hovering) and 1.15 or 1) end end)
row.Destroying:Connect(function()moveConn:Disconnect()endConn:Disconnect()end)
if not TOUCH then hit.MouseEnter:Connect(function()api.hovering=true mspring(hsc,1.15)end) hit.MouseLeave:Connect(function()api.hovering=false if not dragging3 then mspring(hsc,1) end end) end
paint(false) return api
end

local function createESPSection(parent,name,defaultColor,hasHealthStatus,hasProgress,settings_ref)
local acc=createAccordion(parent,name,true,false,13)
if acc.toggle then acc.toggle.onToggle=function(on) settings_ref.enabled=on end end
createToggle(acc.content,"Name",false,function(on)settings_ref.name=on end,12)
createToggle(acc.content,"Distance",false,function(on)settings_ref.distance=on end,12)
if hasHealthStatus then
    createToggle(acc.content,"Health Status",false,function(on)settings_ref.healthStatus=on end,12)
    createColorSetting(acc.content,"Healthy Color",Color3.fromRGB(0,255,0),true,function(color,enabled)settings_ref.healthHealthy.color=color settings_ref.healthHealthy.enabled=enabled end,12)
    createColorSetting(acc.content,"Injured Color",Color3.fromRGB(255,0,0),true,function(color,enabled)settings_ref.healthInjured.color=color settings_ref.healthInjured.enabled=enabled end,12)
end
if hasProgress then createToggle(acc.content,"Progress",false,function(on)settings_ref.progress=on end,12) end
createColorSetting(acc.content,"Outline Color",defaultColor,true,function(color,enabled)settings_ref.outline.color=color settings_ref.outline.enabled=enabled end,12)
createColorSetting(acc.content,"Fill Color",defaultColor,false,function(color,enabled)settings_ref.fill.color=color settings_ref.fill.enabled=enabled end,12)
return acc
end

local function buildVisualTab(parent)
local scroll=new("ScrollingFrame",{Name="VisualContent",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,1,0),CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=4,ScrollBarImageColor3=C.ScrClr or Color3.fromRGB(42,42,53),ScrollBarImageTransparency=0.15,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,Visible=false},parent)
local layout=new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)},scroll)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()scroll.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+10)end)
local esp=createAccordion(scroll,"ESP",false,false,14)
createESPSection(esp.content,"Killer",DEFAULT_COLORS.killer,false,false,Settings.esp.killer)
createESPSection(esp.content,"Survivor",DEFAULT_COLORS.survivor,true,false,Settings.esp.survivor)
createESPSection(esp.content,"Pallet",DEFAULT_COLORS.pallet,false,false,Settings.esp.pallet)
createESPSection(esp.content,"Window",DEFAULT_COLORS.window,false,false,Settings.esp.window)
createESPSection(esp.content,"Generator",DEFAULT_COLORS.generator,false,true,Settings.esp.generator)
createESPSection(esp.content,"Hook",DEFAULT_COLORS.hook,false,false,Settings.esp.hook)
createESPSection(esp.content,"Zombie",DEFAULT_COLORS.zombie,false,false,Settings.esp.zombie)
local render=createAccordion(scroll,"Render",false,false,14)
createSlider(render.content,"FOV",70,120,70,"",function(v)Settings.render.fov=v end)
createSlider(render.content,"Brightness",0,100,50,"%",function(v)Settings.render.brightness=v end)
createToggle(render.content,"No-Fog",false,function(on)Settings.render.noFog=on end,13)
return {container=scroll,settings=Settings,esp=esp,render=render}
end

local function saveErr(msg) pcall(function() writefile("Error.txt",os.date("%Y-%m-%d %H:%M:%S").."\n"..tostring(msg).."\n\n"..debug.traceback()) end) warn("[gw.cc] "..tostring(msg)) end
local ok2,err2=pcall(function()
local visual=buildVisualTab(content)
visual.container.ZIndex=3
_visualContainer=visual.container
navBtns["V"].Activated:Connect(function()visual.container.Visible=true end)
navBtns["M"].Activated:Connect(function()visual.container.Visible=false end)
navBtns["C"].Activated:Connect(function()visual.container.Visible=false end)
end)
if not ok2 then saveErr("WIRE: "..tostring(err2)) end

--============================================================
-- ESP SYSTEM v5 (Stage 1: Window/Vault Fix)
--============================================================
local espObjects={}
local espConn
local espTimer=0

local function espInGame()
    if LocalPlayer:GetAttribute("killerend") then return false end
    local char=LocalPlayer.Character
    if not char or not char.Parent then return false end
    local cam=workspace.CurrentCamera
    if cam and cam.CameraType~=Enum.CameraType.Custom then return false end
    for _,obj in ipairs(CollectionService:GetTagged("Killer")) do
        if obj and obj.Parent and Players:GetPlayerFromCharacter(obj) then
            return true
        end
    end
    return false
end

local function espCureActive()
    for _,p in ipairs(Players:GetPlayers()) do
        if p:GetAttribute("SelectedKiller")=="Cure" and p.Character and p.Character.Parent then
            for _,tag in ipairs(CollectionService:GetTags(p.Character)) do
                if tag=="Killer" then return true end
            end
        end
    end
    return false
end

local function espDist(obj)
    local char=LocalPlayer.Character if not char then return 0 end
    local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return 0 end
    local part=obj
    if obj:IsA("Model") then
        part=obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart
    end
    if not part then return 0 end
    return (hrp.Position-part.Position).Magnitude
end

local function espName(obj,type)
    if type=="killer" or type=="survivor" then
        local p=Players:GetPlayerFromCharacter(obj)
        if p then return p.DisplayName end
    end
    return type:sub(1,1):upper()..type:sub(2)
end

-- ИСПРАВЛЕНО: Window использует BoxHandleAdornment, всё остальное — Highlight
local function espUpdate(obj,type,cfg)
    if not obj or not obj.Parent then return end
    for _,tag in ipairs(CollectionService:GetTags(obj)) do
        if tag=="NoHighlight" then return end
    end
    local entry=espObjects[obj]
    if not entry then entry={} espObjects[obj]=entry end

    -- Highlight (для всего КРОМЕ окон)
    if not entry.highlight and type ~= "window" then
        entry.highlight=Instance.new("Highlight")
        entry.highlight.Name="gwcc_ESP"
        entry.highlight.Adornee = obj
        entry.highlight.Parent = workspace
    end

    -- BoxHandleAdornment (ТОЛЬКО для окон, как у 6locc)
    if not entry.box and type == "window" then
        entry.box=Instance.new("BoxHandleAdornment")
        entry.box.Name="gwcc_ESP_Box"
        entry.box.AlwaysOnTop = true
        entry.box.ZIndex = 5
        entry.box.Transparency = 0.6
        entry.box.Adornee = obj
        entry.box.Parent = workspace
    end

    -- Billboard (для всех)
    if not entry.billboard then
        entry.billboard=Instance.new("BillboardGui")
        entry.billboard.Name="gwcc_ESP_BB"
        entry.billboard.Size=UDim2.fromOffset(200,50)
        entry.billboard.StudsOffset=Vector3.new(0,3,0)
        entry.billboard.AlwaysOnTop=true
        entry.billboard.Adornee = obj
        entry.billboard.Parent = workspace
        entry.label=Instance.new("TextLabel")
        entry.label.Size=UDim2.fromScale(1,1)
        entry.label.BackgroundTransparency=1
        entry.label.Font=Enum.Font.Code
        entry.label.TextSize=14
        entry.label.TextColor3=Color3.new(1,1,1)
        entry.label.Parent=entry.billboard
    end

    entry.type=type
    entry.cfg=cfg

    if not cfg.enabled then
        if entry.highlight then entry.highlight.Enabled=false end
        if entry.box then entry.box.Visible=false end
        entry.billboard.Enabled=false
        return
    end

    local fillColor=cfg.fill.color
    if type=="survivor" and cfg.healthStatus then
        if obj:GetAttribute("Knocked") then
            fillColor=cfg.healthInjured.color
        else
            fillColor=cfg.healthHealthy.color
        end
    end

    -- Применяем цвета для Highlight
    if entry.highlight then
        entry.highlight.Enabled=true
        entry.highlight.OutlineColor=cfg.outline.color
        entry.highlight.OutlineTransparency=cfg.outline.enabled and 0.1 or 1
        entry.highlight.FillColor=fillColor
        entry.highlight.FillTransparency=cfg.fill.enabled and 0.6 or 1
    end

    -- Применяем цвета для Box (окна)
    if entry.box then
        entry.box.Visible=true
        entry.box.Color3=cfg.outline.color
        entry.box.Transparency=cfg.outline.enabled and 0.1 or 1
    end

    local showText=cfg.name or cfg.distance or (type=="generator" and cfg.progress)
    if showText then
        entry.billboard.Enabled=true
        entry.label.TextColor3=cfg.outline.enabled and cfg.outline.color or cfg.fill.color
    else
        entry.billboard.Enabled=false
    end
end

-- ИСПРАВЛЕНО: добавлено удаление entry.box
local function espRemove(obj)
    local e=espObjects[obj]
    if e then
        if e.highlight then e.highlight:Destroy() end
        if e.box then e.box:Destroy() end
        if e.billboard then e.billboard:Destroy() end
        espObjects[obj]=nil
    end
end

-- ИСПРАВЛЕНО: Поиск окон по структуре (точная копия логики 6locc)
local function espScan()
    local seen={}

    -- Killers
    for _,obj in ipairs(CollectionService:GetTagged("Killer")) do
        if obj~=LocalPlayer.Character then seen[obj]=true espUpdate(obj,"killer",Settings.esp.killer) end
    end

    -- Survivors
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character and plr.Character.Parent then
            local isKiller=false
            for _,tag in ipairs(CollectionService:GetTags(plr.Character)) do
                if tag=="Killer" then isKiller=true break end
            end
            if not isKiller then seen[plr.Character]=true espUpdate(plr.Character,"survivor",Settings.esp.survivor) end
        end
    end

    -- Pallets
    for _,obj in ipairs(CollectionService:GetTagged("pallet")) do seen[obj]=true espUpdate(obj,"pallet",Settings.esp.pallet) end

    -- Windows/Vaults (структурное сканирование как у 6locc)
    local mapFolder = workspace:FindFirstChild("Map")
    local scanList = mapFolder and mapFolder:GetDescendants() or workspace:GetDescendants()

    for _, obj in ipairs(scanList) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local name = obj.Name
            local isWindow = (name == "Window" or (name:lower()):find("window") or name == "Vault" or (name:lower()):find("vault"))

            if isWindow then
                local hasBottom, hasInvis, hasTrigger = false, false, false
                for _, child in ipairs(obj:GetDescendants()) do
                    local cname = child.Name:lower()
                    if cname == "bottom" then hasBottom = true
                    elseif cname == "inviswall" then hasInvis = true
                    elseif cname == "vaulttrigger" then hasTrigger = true end
                end

                if hasBottom and hasInvis and hasTrigger then
                    seen[obj] = true
                    espUpdate(obj, "window", Settings.esp.window)
                end
            end
        end
    end

    -- Альтернативный путь: поиск по VaultTrigger (точная копия 6locc)
    for _, obj in ipairs(scanList) do
        if obj:IsA("BasePart") and (obj.Name == "VaultTrigger" or (obj.Name:lower()):find("vaulttrigger")) then
            local parent = obj.Parent
            if parent and (parent:IsA("Model") or parent:IsA("Folder")) and not seen[parent] then
                local hasBottom, hasInvis = false, false
                for _, child in ipairs(parent:GetDescendants()) do
                    local cname = child.Name:lower()
                    if cname == "bottom" then hasBottom = true
                    elseif cname == "inviswall" then hasInvis = true end
                end
                if hasBottom and hasInvis then
                    seen[parent] = true
                    espUpdate(parent, "window", Settings.esp.window)
                end
            end
        end
    end

    -- Generators
    for _,obj in ipairs(CollectionService:GetTagged("Generator")) do
        if obj:GetAttribute("Completed") then espRemove(obj) else seen[obj]=true espUpdate(obj,"generator",Settings.esp.generator) end
    end

    -- Hooks
    for _,obj in ipairs(CollectionService:GetTagged("Spike")) do seen[obj]=true espUpdate(obj,"hook",Settings.esp.hook) end

    -- Zombies (Cure)
    if espCureActive() then
        for _,obj in ipairs(CollectionService:GetTagged("049-2")) do seen[obj]=true espUpdate(obj,"zombie",Settings.esp.zombie) end
    end

    -- Удаление объектов которых больше нет
    for obj in pairs(espObjects) do
        if not seen[obj] or not obj or not obj.Parent then espRemove(obj) end
    end
end

-- ИСПРАВЛЕНО: добавлено управление entry.box в RenderStepped
espConn=RunService.RenderStepped:Connect(function()
    local inGame=espInGame()
    if not inGame then
        for _,e in pairs(espObjects) do
            if e.highlight then e.highlight.Enabled=false end
            if e.box then e.box.Visible=false end
            if e.billboard then e.billboard.Enabled=false end
        end
        return
    end
    espTimer=espTimer+1
    if espTimer>=30 then espTimer=0 espScan() end
    for obj,e in pairs(espObjects) do
        if obj and obj.Parent and e.highlight and e.highlight.Enabled and e.billboard and e.billboard.Enabled and e.cfg then
            local cfg=e.cfg
            local lines={}
            if cfg.name then table.insert(lines,espName(obj,e.type)) end
            if cfg.distance then table.insert(lines,math.floor(espDist(obj)).." studs") end
            if e.type=="generator" and cfg.progress then
                local p=obj:GetAttribute("RepairProgress")
                if p then table.insert(lines,"Progress: "..math.floor(p).."%") end
            end
            e.label.Text=table.concat(lines,"\n")
            local d=espDist(obj)
            e.label.TextSize=math.clamp(14-(d/25),8,14)
        end
    end
end)

gui.Destroying:Connect(function()
    if espConn then espConn:Disconnect() end
    for obj in pairs(espObjects) do espRemove(obj) end
end)

print("[gw.cc] Loaded! Stage 1 (Window/Vault fix) applied.")
