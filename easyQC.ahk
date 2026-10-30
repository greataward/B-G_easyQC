#Requires AutoHotkey v2.0
#SingleInstance force
; =======================================================================================
; ==================================== LOAD VARIABLES ===================================
; =======================================================================================

devMode := IniRead("config.ini", "debug", "devMode", 0)

; CONSTANTS
WINDOW_WIDTH := 371
WINDOW_HEIGHT :=  400
WINDOW_X := devMode ? -600 : 0
WINDOW_Y := devMode ? 160 : 0
FONT_SIZE := 14
TAB_FONT_SIZE := 10
DEFAULT_TAB := devMode ? 3 : 1
tabTitles := [ "Main", "Samples", "Label", "Cores", "Settings"]
tabStatusMessages := ["Press ctrl+1 to output values", "Press ctrl+2 to output values, w/ blank upc", "", "Pick a log sheet and press load", ""]
; COLORS
PALE_BLUE := "eef2ff"
NAVY_BLUE := "4d6d9a"
SOLAR_BLUE := "268bd2"
LIGHT_ORANGE := "fed7aa"
pale_orange := "fdebd0"
DARK_ORANGE := "d57d55" ;"94755c", af8561, 946a6c, 9d816c
DARK_YELLOW := "99873e" ; d4ac0d
SLATE := "94a3b8"
LIGHT_STONE := "e7e5e4"

; GLOBAL VARIABLES TODO: use object.base to move more options to this section
data := {
	initials: { value: "..", displayName: "Initials", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	customer: { value: "<customer>", displayName: "Customer", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	preOrder: { value: "20010", displayName: "Order" },
	postOrder: { value: "....", displayName: "", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	order: { value: "20010....", displayName: "Order", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	upc: { value: "............", displayName: "UPC", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	style: { value: "....", displayName: "Style", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	roll: { value: "1", displayName: "Roll", bg: NAVY_BLUE, bgChanged: DARK_ORANGE },
}
setupForIni(data, "main", hasPreviousValues := true)

settings := {
	delay: { value: 100, displayName: "Delay (ms)" },
	autoStyle: { value: 0, displayName: "Auto Style" },
	quickOrder: { value: 0, displayName: "Quick Order" },
	orderGuard: { value: 1, displayName: "Order Guard (prevent typos)" },
	orderPrefix: { value: "20010", displayName: "Prefix" }, 
	enableFixes: { value: 1, displayname: "Enable Label Fixing" },
	enableSampleButtons: { value: 0, displayname: "Enable Shortage Buttons" }, ; TODO: rename all "Sample" to "Shortage"
	qc4Toggle: { value: 0, displayname: "QC4 Toggle" },
	autoLabelDate: { value: 0, displayName: "Use Today's Date" },
}
setupForIni(settings, "settings")

sampleData := {
	initials:     { value: "ZZ", displayName: "Initials", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	roll:         { value: "1", displayName: "Roll #", bg: PALE_BLUE, bgChanged: PALE_ORANGE, fg: "000000" },
	customer:     { value: "HILLMAN", displayName: "Customer", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	order:        { value: "HILLMAN-", displayName: "Order" },
	date:         { value: "-1-1-25", displayName: "", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	style:        { value: "TAGEOS", displayName: "Style", index: 0, bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	rollId:       { value: "Hillm001", displayName: "Roll Id", bg: PALE_BLUE, bgChanged: PALE_ORANGE },
	styleFilter:  { value: 0},
}
setupForIni(sampleData, "samples", hasPreviousValues := true)



;array of objs: [
;{
;    text: "tageos 241 M7"
;    brand: "tageos"
;    antenna: "241"
;    chip: "M7"
;}]

textInlays := [
    "Tageos 241 M7", "Tageos 241 M8", "Tageos 241 U9", "Tageos 261 M7", "Tageos 261 M8", "Tageos 261 U9",
	"Tageos 300 M7", "Tageos 300 R6", "Tageos 300 U8", "Tageos 300 U9", "Tageos 300 U9", "Tageos 402 R6",
	"Tageos 402 R6", "Tageos 430 M7", "Tageos 430 M8", "Tageos 430 U9",
    "Arizon GR7E M7", "Arizon GR86 M8", "Arizon 430 M7", "Arizon 430 M8",
    "Paragon 261 M7", "Paragon 300 M7", "Paragon 300 R6", "Paragon 402 R6", "Paragon 430 M7",
    "Avery 241 M7", "Avery 241 M8", "Avery 261 M8", "Avery 261 U9", "Avery 300 M7", "Avery 300 U9",
	"Avery 402 M7", "Avery 402 M8", "Avery 402 U9", "Avery 430 U9",
]

fullInlays := [] 
for i, fullString in textInlays {
	str := strSplit(fullString, A_Space)
	fullInlays.Push({ text: fullString, brand: str[1], inlay: str[2], chip: str[3] })
}

brands := []
inlays := []
chips := []
{
	tempObjArr := [{ }, { }, { }] ; easy way to extract uniques bc property names are unique
	tempArrContainer := [brands, inlays, chips] 
	for i, fullString  in textInlays {
		for j, str in StrSplit(fullString, A_Space) {
			if(!tempObjArr[j].HasOwnProp(str)) {
				tempObjArr[j].DefineProp(str, { value: 0 })
				tempArrContainer[j].push({ name: str })
			}
		}
	}
}

labelData := {
	order: { value: "'20010....", displayName: "Order#", index: 1, fixes: ["add_apostrophe"] },
 	upc: { value: "'............", displayName: "UPC", index: 2, fixes: ["add_apostrophe"] },
 	initials: { value: "'..", displayName: "QC By", index: 3, fixes: ["add_apostrophe", "caps"] },
 	date: { value: "../../....", displayName: "Date", index: 4, fixes: ["fix_date"] },
	roll: { value: "1", displayName: "Roll #", index: 5, fixes: ["remove_shortage"] },
 	quantity: { value: "0", displayName: "Qty", index: 6, fixes: ["remove_comma"] },
 	customer: { value: "<customer>", displayName: "Customer", index: 7, fixes: [] },
}
setupForIni(labelData, "label", hasPreviousValues := true)
setupColors(labelData, PALE_BLUE, LIGHT_ORANGE)

samplePlusButton := { }
sampleMinusButton := { }
addStyleButton := { }

paths := {
	rfid_dir: { value: "C:\RFID\PROG\" },
	rfid_file: { value: "RFIDQAR420.exe", displayName: "RFID Program" },
	csv_dir: { value: "C:\RFID\PACKLABEL\", displayName: "CSV Path" },
	csv_file: { value: "RFID-PACKLABEL.csv" },
}
setupForIni(paths, "paths")

; core labels: rolls are read from the log sheet file's config!D24# list (order, upc, roll, qty)
coreData := {
	folder: { value: "" }, ; onedrive synced folder with the log sheets
	initials: { value: "" },
	delay: { value: 1500 }, ; ms to wait after a logo click before writing the next roll
	logoExe: { value: "" },
	logoClass: { value: "" },
	logoX1: { value: "" },
	logoY1: { value: "" },
	logoX2: { value: "" },
	logoY2: { value: "" },
}
setupForIni(coreData, "cores")

cores := {
	files: [],     ; log sheet paths in the dropdown
	rows: [],      ; { order, upc, roll, qty, key }
	order: "",
	customer: "",
	current: 0,    ; row whose values are in the csv, waiting for a logo click
	sentStack: [], ; rows sent this run, for the back button
	paused: false,
	pendingClick: false,
	logoStep: 0,
	logoCountdown: 0,
}

csv := { }
defaultButtons := [{}, {}, {}, {}, {}]

history := { index: { value: 0} }
Loop 10 {
	i := A_Index - 1
	for (key, item in ["initials", "customer", "order", "upc", "style", "roll", "time"]) {
		history.%item . i% := { value: "" }
	}
}
setupForIni(history, "history")

; =======================================================================================
; ===================================== CREATE GUI ======================================
; =======================================================================================

myGui := Gui("+0x40000") ; resizable
myGui.MarginX := 10
myGui.Marginy := 10
setupGuiAppearance()

statusBar := myGui.AddStatusBar("xs", "")
statusBar.SetFont("s10")

Tab := setupTabs()
setupMainTab(1)
setupSamplesTab(2)
setupLabelTab(3)
setupCoresTab(4)
setupSettingsTab(5)
onTabChange(Tab)

myGui.OnEvent("Close", (*) => ExitApp)
myGui.Show(Format(devMode ? "w{1} h{2} x{3} y{4}" : "w{1} h{2}",
	WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_X, WINDOW_Y))

; =======================================================================================
; ===================================== FUNCTIONS =======================================
; =======================================================================================

setupForIni(items, section, hasPreviousValues := false) {
	for (key, item in items.OwnProps()) {
		item.iniName := key
		item.iniSection := section
		item.value := readItem(item)

		if (hasPreviousValues)
			item.prevValue := readItemPrev(item)
	}
}
setupColors(items, bg, bgChanged) {
	for (key, item in items.OwnProps()) {
		item.bg := bg
		item.bgChanged := bgChanged
	}
}

checkOrderTypo() {
	prefix := SubStr(data.order.gui.value, 1, 6)
	if (settings.quickOrder.gui.value) {
		prefix := settings.orderPrefix.gui.value . SubStr(data.postOrder.gui.value, 1, 1)
	}

	isOrderGuard := settings.orderGuard.gui.value
	isTypo := (prefix = "200100" || prefix = "200119")

	newColor := (isTypo && isOrderGuard)  ? "cRed" : "cBlack"
	data.order.gui.setFont(newColor)
	data.postOrder.gui.setFont(newColor)
}

saveItem(item) {
	switch (item.iniSection . "." . item.iniName) {
		case "main.order":
		data.postOrder.gui.value := SubStr(item.gui.value, -4)
		writeItem(data.postOrder)
		checkOrderTypo()

		case "main.upc":
		updateStyleLock()

		case "main.postOrder":
		data.order.gui.value := settings.orderPrefix.gui.value . item.gui.value
		writeItem(data.order)
		checkOrderTypo()

		case "settings.orderPrefix":
		data.preOrder.gui.value := item.gui.value
		writeItem(data.preOrder)
		checkOrderTypo()

		case "samples.customer":
		sampleData.order.gui.value := removeCounter(sampleData.customer.gui.value ) . "-"
		writeItem(sampleData.order)

		case "main.roll": 
		updateSampleButtons()

		case "settings.autoStyle":
		updateStyleLock()

		case "settings.quickOrder":
		updateQuickOrderVisibility()
        checkOrderTypo()

		case "settings.enableFixes":
		updateFixVisibility()

		case "settings.enableSampleButtons":
		updateSampleButtonsVisibility()
	}

	if (item.iniSection == "label" && item.HasProp("fixButton"))
		item.fixButton.visible := settings.enableFixes.gui.value ? canFix(item) : false

	writeItem(item)
	updateItemBg(item)
}

removeCounter(txt) {
	pos := RegExMatch(txt, "-?[0-9]+$")
	return (pos <= 0) ? txt : SubStr(txt, 1, pos - 1)
}

updateFixVisibility() {
	for (key, item in labelData.OwnProps())
		if item.HasProp("fixButton")
			item.fixButton.Visible := settings.enableFixes.gui.value ? canFix(item) : false
}
updateSampleButtonsVisibility() {
	for (key, item in [samplePlusButton, sampleMinusButton])
		if item.HasProp("gui")
			item.gui.Visible := settings.enableSampleButtons.gui.value
}

updateItemBg(item) {
	if item.HasProp("prevValue") && item.HasProp("bg") && item.gui.Enabled && item.gui.Visible {
		if (StrCompare(item.gui.value, item.prevValue, 1))
			item.gui.Opt("Background" . item.bgChanged)
		else
			item.gui.Opt("Background" . item.bg)
		item.gui.Opt("+Redraw")
	}
}
clearBgsForWrite(items) {
	for key, item in items.OwnProps(){
		if (item.gui.value != item.prevValue)
			item.gui.Opt("Background" . PALE_BLUE)
		else
			item.gui.Opt("-Background")
		item.gui.Opt("+Redraw")
	}
}
updatePrevValues(items) {
	for (key, item in items.OwnProps()) {
		if (HasProp(item, "gui")) {
			item.prevValue := item.gui.value
			writeItemPrev(item)
			updateItemBg(item)
		}
	}
}

updatePrevSampleValues() {

}

writeItem(item) => IniWrite(item.gui.value, "config.ini", item.iniSection, item.iniName) 
readItem(item) => IniRead("config.ini", item.iniSection, item.iniName, item.value)
writeItemPrev(item) => IniWrite(item.gui.value, "config.ini", item.iniSection, "prev_" . item.iniName)
readItemPrev(item) => IniRead("config.ini", item.iniSection, "prev_" . item.iniName, item.value)
writeHistory(item) => IniWrite(item.value, "config.ini", "history", item.iniName) 
hasGui(item) => item.HasProp("gui")

onStyleFilterChange(*) {
	value := sampleData.styleFilter.gui.text

	sampleData.style.gui.Delete()
	names := []
	for i, inlay in inlays.All {
		if (inlay.brand == value || inlay.inlay == value || inlay.chip == value) {
			names.Push(inlay.name)
			continue
		}
	}
	sampleData.style.gui.Add(names)
}

updateCheckboxes() {
	toggles := Map()
	for i, v in brands
		toggles[v.name] := v.gui.value
	for i, v in inlays
		toggles[v.name] := v.gui.value
	for i, v in chips
		toggles[v.name] := v.gui.value

	sampleData.style.gui.Delete()
	for i, obj in fullInlays
		if (toggles.Get(obj.brand) && toggles.Get(obj.inlay) && toggles.Get(obj.chip))
			sampleData.style.gui.Add([obj.text])
	sampleData.style.gui.Redraw()
}

onTabChange(tabObj) {
	statusBar.SetText(tabStatusMessages[tabObj.Value])
	tabNum := tabObj.value
	defaultButtons[tabNum].Opt("+Default")

	if (tabNum == cores.tabNum) {
		refreshCoreFiles()
		updateCoresStatus()
	}
}

clearItems(items) {
	for key, item in items.OwnProps() {
		if (!item.gui.Enabled)
			continue
		item.gui.value := ""
		saveItem(item) ; TODO: find out why it's not saving roll clear
	}
	updatePrevValues(items)
}

showHistory(*) {
	out := ""
	fields := ["time", "initials", "customer", "order", "upc", "style", "roll"]
	indicies := [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]

	for i, v in indicies {
		indicies[i] := Mod(indicies[i] + history.index.value, 10)
	}

	for i, index in indicies {
		for j, field in fields {
			item := history.%field . index%
			out .= field . "`t : " . item.value . "`n"
		}
		out .= "`n"
	}
	msgBox(out)
}

saveHistory(fullOrder) {
	i := history.index.value

	initials := history.%'initials' . i%
	customer := history.%'customer' . i%
	order := history.%'order' . i%
	upc := history.%'upc' . i%
	style := history.%'style' . i%
	roll := history.%'roll' . i%
	time := history.%'time' . i%

	initials.value := data.initials.gui.value
	customer.value := data.customer.gui.value
	order.value := fullOrder
	upc.value := data.upc.gui.value
	style.value := data.style.gui.value
	roll.value := data.roll.gui.value
	time.value := FormatTime()

	history.index.value := Mod(history.index.value + 1, 10)
	for index, item in [initials, customer, order, upc, style, roll, time, history.index] {
		writeHistory(item)
	}
}

setupGuiAppearance() {
	myGui.Title := devMode ? "easyQC - dev mode" : "easyQC"
	myGui.SetFont("s" . FONT_SIZE, "Verdana")
	myGui.SetFont(, "Courier")
	myGui.SetFont(, "Courier New")
}

setupTabs() {
	myGui.SetFont("s" . TAB_FONT_SIZE)
	Tab := myGui.AddTab3("-wrap choose" . DEFAULT_TAB, tabTitles)
	myGui.SetFont("s" . FONT_SIZE)

	Tab.OnEvent("Change", (*) => onTabChange(Tab))
	return Tab
}

setupMainTab(tabNum) {
	Tab.useTab(tabNum)
	myGui.AddGroupBox("w330 h275 cGray Section", "data")

	; INITIALS
	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { uppercase: true, charLimit: 2, ySection: 0, width: 40, background: data.initials.bg }
	createEdit(data.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 170, background: data.customer.bg }
	createEdit(data.customer, textOpt, editOpt)

	; ====================== ORDER / QUICK_ORDER ====================
	; ===============================================================

	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 9, ySection: 0, width: 130, background: data.order.bg }
	createEdit(data.order, textOpt, editOpt)

	editOpt := { number: true, charLimit: 5, xPrev: 0, ySection: 0, width: 82 }
	createEditboxOnly(data.preOrder, editOpt)
	editOpt := { number: true, charLimit: 4, xPrev: 100, ySection: 0, width: 70, background: data.postOrder.bg }
	createEditboxOnly(data.postOrder, editOpt)

	data.preOrder.gui.Enabled := false
	updateQuickOrderVisibility()

	; ===============================================================
	; ===============================================================

	; UPC
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 12, ySection: 0, width: 170, background: data.upc.bg }
	createEdit(data.upc, textOpt, editOpt)

	; STYLE
	textOpt := { xSection: 0, newSection: true }
	editOpt := { number: true, charLimit: 4, ySection: 0, width: 60, background: data.style.bg }
	createEdit(data.style, textOpt, editOpt)
	updateStyleLock()

	; ROLL
	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 5, ySection: 0, width: 70, background: data.roll.bg, center: True }
	fontOpt := { bold: true, foreground: PALE_BLUE, fontName: "Arial"}
	createEdit(data.roll, textOpt, editOpt, fontOpt)
	myGui.AddUpDown("Range1-200 Wrap", data.roll.value)

	; SAMPLE BUTTONS
	buttonOpt := { xSection: 200, ySection: -5, width: 20, height: 20, stopTab: true} ; 286 aligns right edge
	fontOpt := { fontSize: 8 }
	samplePlusButton.gui := createButton(buttonOpt, "s+", (*) => addSample("plus"), fontOpt)
	buttonOpt := { xPrev: 0, yPrev: 20, width: 20, height: 20, stopTab: true}
	fontOpt := { fontSize: 8 }
	sampleMinusButton.gui := createButton(buttonOpt, "s-", (*) => addSample("minus"), fontOpt)

	updateSampleButtons()
	samplePlusButton.gui.Visible := settings.enableSampleButtons.value
	sampleMinusButton.gui.Visible := settings.enableSampleButtons.value


	; CLEAR BUTTON
	buttonOpt := { xMargin: 288, yMargin: 275 + TAB_FONT_SIZE, width: 50, height: 20, stopTab: true}
	fontOpt := { fontSize: 8 }
	createButton(buttonOpt, "CLEAR", (*) => clearItems(data), fontOpt)

	; HISTORY BUTTON
	buttonOpt := { xMargin: 315, yMargin: 15 + TAB_FONT_SIZE, width: 45, height: 16, stopTab: true }
	fontOpt := { fontSize: 7, fontName: "Consolas" }
	createButton(buttonOpt, "history", (*) => showHistory(), fontOpt)


	createDefaultEnterButton(tabNum)
}

updateStyleLock() {
	if (hasGui(settings.autoStyle))
		isAutoStyle := settings.autoStyle.gui.value
	else
		isAutoStyle := readItem(settings.autoStyle)

	data.style.gui.Enabled := !isAutoStyle
	data.style.gui.value := isAutoStyle ? SubStr(data.upc.gui.value, -4) : data.style.gui.value
	data.style.textGui.setFont(isAutoStyle ? "cSilver" : "cBlack")
}

setupSamplesTab(tabNum) {
	Tab.UseTab(tabNum)
	myGui.AddGroupBox("w340 h235 cGreen Section", "sample data")

	; INITIALS 
	textOpt := { xPrev: 20, yPrev: 25, newSection: true }
	editOpt := { uppercase: true, charLimit: 2, ySection: 0, width: 40 } 
	createEdit(sampleData.initials, textOpt, editOpt)

	; CUSTOMER
	textOpt := { yPrev: 35, xSection: 0, newSection: true, noMulti: true }
	editOpt := { ySection: 0, width: 207, background: sampleData.customer.bg }
	createEdit(sampleData.customer, textOpt, editOpt)
 
	; ORDER
	textOpt := { yPrev: 35, xSection: 0, newSection: true }
	editOpt := { ySection: 0, width: 121, justify: "Left" , noMulti: true}
	fontOpt := { fontSize: 11, fontName: "Consolas" }
	createEdit(sampleData.order, textOpt, editOpt, fontOpt)
	sampleData.order.gui.Enabled := false

	editOpt := { xPrev: 122, ySection: 0, width: 85, noMulti: true, background: sampleData.date.bg  }
	fontOpt := { fontSize: 12, fontName: "Consolas" }
	createEditBoxOnly(sampleData.date, editOpt, fontOpt)


	; ORIGINAL STYLE
	textOpt := { yPrev: 35, xSection: 0, newSection: true, noMulti: true }
	editOpt := { ySection: 0, width: 180, background: sampleData.style.bg }
	myGui.AddText(formatOptions(textOpt), "   Style:")
	fontOpt := { fontSize: 12, fontName: "Aptos Narrow", foreground: SLATE, bold: true }
	sampleData.style.gui := myGui.AddComboBox(formatOptions(editOpt), textInlays )
	sampleData.style.gui.setFont(formatOptions(fontOpt), fontOpt.fontName)

	; ROLL
	textOpt := { yPrev: 35, xSection: 0, newSection: true }
	editOpt := { charLimit: 12, ySection: 0, width: 70, background: sampleData.roll.bg }
	fontOpt := { fontSize: 14, fontName: "Arial", foreground: sampleData.roll.fg }
	createEdit(sampleData.roll, textOpt, editOpt, fontOpt)
	myGui.AddUpDown("Range1-200 Wrap", sampleData.roll.value)

	; ROLL ID
	textOpt := { yPrev: 35, xSection: 0, newSection: true, noMulti: true }
	editOpt := { ySection: 0, width: 207, background: sampleData.rollId.bg }
	createEdit(sampleData.rollId, textOpt, editOpt)

	; STYLE_FILTER

;   textOpt := { yPrev: 30, xSection: 85, newSection: true }
;	fontOpt := { fontSize: 8, fontName: "Aptos Narrow", foreground: SLATE }
;	tempText := myGui.AddText(formatOptions(textOpt), "Style Filter")
;	tempText.setFont(formatOptions(fontOpt))

;	editOpt := 	{ xPrev: 90, ySection: -2, width: 140, background: LIGHT_STONE, stopTab: true }
;	fontOpt := { fontSize: 8, fontName: "Aptos Narrow", foreground: SLATE, bold: true }

;	sampleData.styleFilter.gui := myGui.AddDropDownList(formatOptions(editOpt), sampleData.styleFilter.titles)
;	sampleData.styleFilter.gui.onEvent("Change", (*) => onStyleFilterChange())
;	sampleData.styleFilter.gui.setFont(formatOptions(fontOpt), fontOpt.hasProp("fontName") ? fontOpt.fontName : "")

	; FILTER CHECKBOXES
	myGui.AddGroupBox("xm12 yp40 w340 h85 cGray Section", "filters")
	fontOpt := { fontSize: 7, fontName: "Aptos Narrow", foreground: SLATE }

	for index, items in [brands, inlays, chips] {
		w := 270 / items.Length
		x0 := (index == 1) ? 10 : 0
		newRowOpt := FormatOptions({ checked: true, width: w, xSection: x0, yPrev: 20, noMulti: true, stopTab: true, newSection: true })
		newColOpt := FormatOptions({ checked: true, width: w,  ySection: 0, noMulti: true, stopTab: True })

		for i, item in items {
			item.gui := myGui.addCheckBox( (i == 1 ? newRowOpt : newColOpt), item.name)
			item.gui.setFont(formatOptions(fontOpt))
			item.gui.OnEvent("Click", (*) => updateCheckboxes())
		}
	}

	updateCheckboxes()
	createDefaultEnterButton(tabNum)
}

setupLabelTab(tabNum) {
	Tab.UseTab(tabNum)
	myGui.MarginY := 6
	myGui.SetFont("s12")
	boxHeight := 24

	; ==== ACTIONS ==== 
	myGui.AddGroupBox("w330 h65 cGray Section", "actions")
	readButton := MyGui.AddButton("xp+10 yp+20 h30 -TabStop", "read")
	readButton.OnEvent("Click", onRead)
	writeButton := MyGui.AddButton("x+15 yp h30 -TabStop", "write")
	writeButton.OnEvent("Click", onWrite)

	; Use Today's Date Checkbox
	myGui.SetFont("s8")
	opt := { xSection: 190, ySection: 20, checked: settings.autoLabelDate.value }
	createCheckbox(settings.autoLabelDate, opt, onAutoDate)

	myGui.SetFont("s8")
	path := (devMode ? ".\test\" : paths.csv_dir.value) . paths.csv_file.value
	pathText := MyGui.AddText("xS+22 yS+55 cGray", "Path: " . path)
	myGui.SetFont("s12")

	; ==== LABEL DATA ====
	myGui.AddGroupBox("xS w330 h245 cBlue Section", "label data")

	quickFixButtonSetup(item) {
		if item.fixes.length == 0
			return
		btnOptions := { xPrev: 160 + 30, yPrev: 0, height: 25, width: 25, stopTab: true }
		item.fixButton := createButton(btnOptions, "fix", (*) => fixItem(item))
		item.fixButton.SetFont("s6")
		item.fixButton.Visible := readItem(settings.enableFixes) && canFix(item)
	}

	; ORDER
	textOpt := { xSection: 10, ySection: 25, newSection: true, height: boxHeight }
	editOpt := { ySection: 0, width: 160, height: boxHeight }
	createEdit(labelData.order, textOpt, editOpt)
	quickFixButtonSetup(labelData.order)

	; UPC
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { ySection: 0, width: 160, height: boxHeight }
	createEdit(labelData.upc, textOpt, editOpt)
	quickFixButtonSetup(labelData.upc)

	; INITIALS
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { charLimit: 4, ySection: 0, width: 50, height: boxHeight}
	createEdit(labelData.initials, textOpt, editOpt)
	quickFixButtonSetup(labelData.initials)

	; DATE 
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { charLimit: 10, ySection: 0, width: 130, height: boxHeight}
	createEdit(labelData.date, textOpt, editOpt)
	quickFixButtonSetup(labelData.date)
	; auto date after settings tab is loaded

	; ROLL
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { charLimit: 5, ySection: 0, width: 70, height: boxHeight }
	createEdit(labelData.roll, textOpt, editOpt)
	x := myGui.AddUpDown("Range1-200 Wrap", labelData.roll.value)
	labelData.roll.gui.value := readItem(labelData.roll)
	quickFixButtonSetup(labelData.roll)

	; QTY
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { number: true, charLimit: 6, ySection: 0, width: 70, height: boxHeight }
	createEdit(labelData.quantity, textOpt, editOpt)
	quickFixButtonSetup(labelData.quantity)

	; CUSTOMER
	textOpt := { xSection: 0, newSection: true, height: boxHeight }
	editOpt := { ySection: 0, width: 130, height: boxHeight }
	createEdit(labelData.customer, textOpt, editOpt)

	myGui.SetFont("s14")
	myGui.MarginY := 11

	createDefaultEnterButton(tabNum)
	for key, item in labelData.OwnProps() {
		updateItemBg(item)
	}
}

setupCoresTab(tabNum) {
	Tab.UseTab(tabNum)
	cores.tabNum := tabNum
	myGui.MarginY := 6
	myGui.SetFont("s10")

	; ==== LOG SHEET ====
	myGui.AddGroupBox("w330 h58 cGray Section", "log sheet")
	cores.fileGui := myGui.AddDropDownList("xs+10 ys+22 w170")
	cores.fileGui.SetFont("s9", "Arial")
	refreshButton := myGui.AddButton("x+5 yp-1 w30 h26 -TabStop", "↻")
	refreshButton.SetFont(, "Segoe UI Symbol")
	refreshButton.OnEvent("Click", refreshCoreFiles)
	folderButton := myGui.AddButton("x+5 yp w30 h26 -TabStop", "…")
	folderButton.OnEvent("Click", onCoresFolder)
	loadButton := myGui.AddButton("x+5 yp w65 h26 -TabStop", "load")
	loadButton.OnEvent("Click", onCoresLoad)

	; ==== ROLLS ====
	myGui.AddGroupBox("xs w330 h238 cBlue Section", "rolls")
	cores.infoGui := myGui.AddText("xs+10 ys+20 w310 cGray", "no log sheet loaded")
	myGui.SetFont("s9", "Arial")
	cores.listGui := myGui.AddListView("xs+5 y+4 w320 h150 Checked -Multi Grid", ["", "UPC", "Roll", "Qty", "Sent"])
	for col, width in [34, 94, 40, 46, 82]
		cores.listGui.ModifyCol(col, width)
	cores.listGui.OnEvent("DoubleClick", onCoresDoubleClick)
	myGui.SetFont("s10", "Courier New")

	myGui.AddText("xs+10 y+10", "QC By:")
	coreData.initials.gui := myGui.AddEdit("x+5 yp-3 w45 Limit4 Uppercase", coreData.initials.value)
	coreData.initials.gui.OnEvent("Change", (*) => saveItem(coreData.initials))
	startButton := myGui.AddButton("x+10 yp-1 w55 h26 -TabStop", "start")
	startButton.OnEvent("Click", onCoresStart)
	backButton := myGui.AddButton("x+5 yp w50 h26 -TabStop", "back")
	backButton.OnEvent("Click", onCoresBack)
	cores.pauseButton := myGui.AddButton("x+5 yp w65 h26 -TabStop", "pause")
	cores.pauseButton.OnEvent("Click", onCoresPause)

	; ==== LOGO AREA ====
	myGui.SetFont("s8")
	logoButton := myGui.AddButton("xs y+14 h22 -TabStop", "set logo area")
	logoButton.OnEvent("Click", onCoresSetLogo)
	cores.logoGui := myGui.AddText("x+8 yp+4 w220 cGray", "")
	updateLogoText()
	myGui.SetFont("s14")
	myGui.MarginY := 11

	createDefaultEnterButton(tabNum)
}

setupSettingsTab(tabNum) {
	Tab.UseTab(tabNum)
	myGui.SetFont("s12")
	myGui.MarginY := 5

	myGui.AddGroupBox("w330 h320 cGray Section", "general")

	textOpt := { xPrev: 20, yPrev: 30, newSection: true }
	editOpt := { ySection: 0, width: 80 }
	createEdit(settings.delay, textOpt, editOpt)
	myGui.AddUpDown("range1-9999 Wrap", settings.delay.value)

	opt := { xSection: 0, newSection: true, checked: settings.autoStyle.value }
	createCheckbox(settings.autoStyle, opt, (*) => saveItem(settings.autoStyle))

	opt := { xSection: 0, newSection: true, checked: settings.quickOrder.value }
	createCheckbox(settings.quickOrder, opt, (*) => saveItem(settings.quickOrder))

	myGui.SetFont("s8") 
	opt := { ySection: 0, xPrev: 210, checked: settings.qc4Toggle.value }
	createCheckbox(settings.qc4Toggle, opt, (*) => saveItem(settings.qc4Toggle))
	myGui.SetFont("s12")

	textOpt := { xSection: 0, newSection: true }
	editOpt := { charLimit: 5, ySection: 0, width: 80 }
	createEdit(settings.orderPrefix, textOpt, editOpt)
	updateQuickOrderVisibility()

	opt := { xSection: 0, newSection: true, checked: settings.orderGuard.value }
	createCheckbox(settings.orderGuard, opt, (*) => saveItem(settings.quickOrder))
	checkOrderTypo()

	textOpt := { xSection: 0, newSection: true }
	editOpt := { xSection: 0, width: 260 }
	fontOpt := { fontSize: 12, fontName: "Consolas" }
	createEdit(paths.rfid_file, textOpt, editOpt, fontOpt)
	paths.rfid_file.textGui.SetFont("s12")

	textOpt := { xSection: 0, newSection: true }
	editOpt := { xSection: 0, width: 260 }
	fontOpt := { fontSize: 11, fontName: "Consolas" }
	createEdit(paths.csv_dir, textOpt, editOpt, fontOpt)
	paths.csv_dir.textGui.SetFont("s12")

	opt := { xSection: 0, newSection: true, checked: settings.enableFixes.value }
	createCheckbox(settings.enableFixes, opt, (*) => saveItem(settings.enableFixes))
	onAutoDate() ; update initial state of date based on autoLabelDate and enableFixes checkbox states

	opt := { xSection: 0, newSection: true, checked: settings.enableSampleButtons.value }
	createCheckbox(settings.enableSampleButtons, opt, (*) => saveItem(settings.enableSampleButtons))

	createDefaultEnterButton(tabNum)
	myGui.SetFont("s14")
	myGui.MarginY := 11
}

createDefaultEnterButton(tabNum) {
	defaultButtons[tabNum] := myGui.AddButton("x0 y0 Default", "button")
	defaultButtons[tabNum].Visible := false
	defaultButtons[tabNum].onEvent("Click", (*) => SendInput("{Tab}"))
}

createEditboxOnly(item, editboxOptions, fontOptions?) {
	item.gui := myGui.AddEdit(formatOptions(editboxOptions), item.value)

	if (IsSet(fontOptions))
		item.gui.setFont(formatOptions(fontOptions), fontOptions.hasProp("fontName") ? fontOptions.fontName : "")

	item.gui.onEvent("Change", (*) => saveItem(item))
}

createEdit(item, textOptions, editboxOptions, fontOptions?) {
	displayName := Format("{:8}", item.displayName) . ":" ;; align right 8 characters

	if (!(textOptions.hasProp("hide") && textOptions.hide))
		item.textGui := myGui.AddText(formatOptions(textOptions), displayName)
	item.gui := myGui.AddEdit(formatOptions(editboxOptions), item.value)

	if (IsSet(fontOptions))
		item.gui.setFont(formatOptions(fontOptions), fontOptions.hasProp("fontName") ? fontOptions.fontName : "")

	item.gui.onEvent("Change", (*) => saveItem(item))
}
createButton(buttonOptions, name, my_function, fontOptions?) {
	btn := myGui.AddButton(formatOptions(buttonOptions), name)
	btn.Opt("+Default")
	btn.onEvent("Click", my_function)

	if (IsSet(fontOptions))
		btn.setFont(formatOptions(fontOptions),
	fontOptions.hasProp("fontName") ? fontOptions.fontName : "")

	return btn
}
createCheckbox(item, options, my_function) {
	checkString := item.value ? " checked1" : "checked0"
	item.gui := myGui.AddCheckBox(formatOptions(options) . checkString, item.displayName)
	item.gui.onEvent("Click", my_function)
}

fixItem(item) {
	for index, fix in item.fixes {
		value := item.gui.value
		switch fix {
			case "add_apostrophe":
			firstChar := SubStr(value, 1, 1)
			if (firstChar != "'")
				item.gui.value := "'" . value

			case "remove_apostrophe":
			firstChar := SubStr(value, 1, 1)
			if (firstChar == "'")
				item.gui.value := SubStr(value, 2) ; TODO: test this

			case "caps":
			item.gui.value := StrUpper(value)

			case "fix_date":
			strings := StrSplit(value, "/")
			month := strings[1], day := strings[2], year := strings[3]
			if StrLen(month) == 1
				month := "0" . month
			if StrLen(day) == 1
				day := "0" . day
			if StrLen(year) == 2
				year := "20" . year
			item.gui.value := month . "/" . day . "/" . year

			case "remove_shortage":
			item.gui.value := String(Floor(Number(value)))

			case "remove_comma":
			item.gui.value := RegExReplace(value, ",", "")
		}
	}
	saveItem(item)
}

canFix(item) {
	for index, fix in item.fixes {
		value := item.gui.value
		switch fix {
			case "add_apostrophe":
			regexString := ""
			if item.displayName == "Order#"
				regexString := "^[0-9]{9}$"
			else if item.displayName == "UPC"
				regexString := "^[0-9]{12}$"
			else if item.displayName == "QC By"
				regexString := "^[a-zA-Z]{2,3}$"
			if RegExMatch(value, regexString)
				return true

			case "remove_apostrophe":
			if RegExMatch(value, "^'[0-9]{12}$")
				return true

			case "caps":
			trimmed := LTrim(value, "'")
			if (!IsUpper(trimmed) && RegexMatch(LTrim(value, "'"), "^\w+$"))
				return true

			case "remove_shortage":
			if IsFloat(value)
				return true

			case "fix_date": ; can have 1-2 day digits, 1-2 month, and 2 or 4 year, but not 3
			if !RegExMatch(value, "^\d\d/\d\d/\d\d\d\d$") 
				&& RegExMatch(value, "^\d\d?/\d\d?/\d\d\d?\d?$")
			&& !RegExMatch(value, "^\d\d?/\d\d?/\d\d\d$") {
				return true
				}

			case "remove_comma":
			if RegExMatch(value, ",")
				return true
		}
	}
	return false
}

updateQuickOrderVisibility() {
	if (hasGui(settings.quickOrder))
		isQuickOrder := settings.quickOrder.gui.value
	else
		isQuickOrder := readItem(settings.quickOrder)

	data.order.gui.Visible := !isQuickOrder
	data.preOrder.gui.Visible := isQuickOrder
	data.postOrder.gui.Visible := isQuickOrder

	if(settings.orderPrefix.HasProp("gui")) {
		settings.orderPrefix.textGui.Enabled := isQuickOrder
		settings.orderPrefix.gui.Enabled := isQuickOrder
	}
}

addSample(type) {
	rollString := data.roll.gui.value
	if(!isNumber(rollString) || Number(rollString) < 0)
		return MsgBox("Error: current roll value is not a number or is negative, cannot change to add sample")
	rollNum := Round(Number(rollString), 1)
	modulus := Round(Mod(rollNum, 1), 1)

	switch {
		case (type == "plus" && modulus <= 0.1):
		rollNum := Round(rollNum + 0.2, 1)
		case (type == "plus" && modulus < 0.9):
		rollNum := Round(rollNum + 0.1, 1)
		case (type == "minus" && modulus <= 0.2):
		rollNum := Round(rollNum, 0)
		case (type == "minus" && modulus <= 0.9):
		rollNum := Round(rollNum - 0.1, 1)
	}
	data.roll.gui.value := rollNum
	saveItem(data.roll)
	updateSampleButtons()
}

updateSampleButtons() {
	rollString := data.roll.gui.value
	if(!isNumber(rollString) || Number(rollString) < 0) {
		samplePlusButton.gui.Enabled := 0
		sampleMinusButton.gui.Enabled := 0
		return
	}
	rollNum := Round(Number(rollString), 1)
	modulus := Round(Mod(rollNum, 1), 1)


	samplePlusButton.gui.Enabled := (modulus < 0.9)
	sampleMinusButton.gui.Enabled := (modulus >= 0.2)
}

onRead(*) {
	if !readCsv()
		return

	settings.autolabelDate.gui.value := 0 ; Toggle off use todays date
	onAutoDate()

	for key1, csvItem in csv.OwnProps()
        for key2, labelItem  in labelData.OwnProps()
	        if (labelItem.index == csvItem.index) {
			    labelItem.gui.value := csvItem.value
			    saveItem(labelItem)
		    }

	updatePrevValues(labelData)
}

onAutoDate(*) {
	saveItem(settings.autoLabelDate)
	isChecked := settings.autoLabelDate.gui.value
	labelData.date.gui.value := isChecked ? getDate() : readItem(labelData.date)
	labelData.date.gui.Enabled := !isChecked

	labelData.date.fixButton.visible := settings.enableFixes.gui.value ? canFix(labelData.date) : false
}

getDate(*) => A_MM . "/" . A_DD . "/" . A_YYYY

csvConcat(array) {
	out .= ""
	for (index, value in array)
		out .= "`"" . value . "`"" . (index != array.Length ? "," : "")
	return out
}
onWrite(*) {
	try {
		csvKeysArray := ["","","","","","",""]
		csvValuesArray := ["","","","","","",""]
		for key, item in labelData.OwnProps() {
			csvKeysArray[item.index] := item.displayName
			csvValuesArray[item.index] := item.gui.value
		}
		csvKeys := csvConcat(csvKeysArray)
		csvValues := csvConcat(csvValuesArray)
		csvOut := csvKeys . "`n" . csvValues
		csvPath := (devMode ? ".\test\out_" : paths.csv_dir.gui.value) . paths.csv_file.value
		file := FileOpen(csvPath, "w")
		file.Write(csvOut)
		file.Close()
		clearBgsForWrite(labelData)
		return true
	} catch as e {
		MsgBox("An error ocurred during writing try path: " . csvPath . "`n" . e.Message)
		return false
	}
}
readCsv(*) {
	csvPath := (devMode ? ".\test\" : paths.csv_dir.gui.value) . paths.csv_file.value
	try {
		Loop read, csvPath {
			line := A_Index
			Loop parse, A_LoopReadLine, "CSV" {
				i := A_Index
				if (line == 1)
					csv.%A_LoopField% := { index: i, value: "" }
				else if (line == 2)
					For key, val in csv.OwnProps()
				if (csv.%key%.index == i)
					csv.%key%.value := A_LoopField
			}
		}
	}
	catch Error as e {
		MsgBox("An error occured:`n`n" . e.Message . "`n`nPlease check that the path is correct: " . csvPath . "`nAlso check that the csv file is in the correct format.")
		return 0
	}
	return 1
}

; ==================================== CORE LABELS ======================================

; log sheets are read from the onedrive synced folder (no excel on the core label computer), newest first
refreshCoreFiles(*) {
	selected := cores.fileGui.Value ? cores.files[cores.fileGui.Value] : ""
	list := ""
	if (coreData.folder.value != "" && DirExist(coreData.folder.value))
		Loop Files, coreData.folder.value . "\*.xlsx", "FR"
			if (SubStr(A_LoopFileName, 1, 2) != "~$") ; excel lock files
				list .= A_LoopFileTimeModified . "`t" . A_LoopFileFullPath . "`n"

	cores.files := []
	names := []
	if (list != "")
		for i, line in StrSplit(Sort(RTrim(list, "`n"), "R"), "`n") {
			if (i > 40)
				break
			path := StrSplit(line, "`t")[2]
			SplitPath(path,,,, &name)
			cores.files.Push(path)
			names.Push(name)
		}
	cores.fileGui.Delete()
	cores.fileGui.Add(names)
	for i, path in cores.files
		if (i == 1 || path == selected)
			cores.fileGui.Choose(i)
}

onCoresFolder(*) {
	folder := DirSelect("*" . coreData.folder.value, 0, "Choose the OneDrive folder with the log sheets")
	if (folder == "")
		return
	coreData.folder.value := folder
	IniWrite(folder, "config.ini", "cores", "folder")
	refreshCoreFiles()
}

onCoresLoad(*) {
	flushLogoClick()
	if (cores.fileGui.Value == 0) {
		if (coreData.folder.value == "")
			return MsgBox("Press … to choose the OneDrive folder with the log sheets.")
		return MsgBox("No log sheets (.xlsx) found in:`n" . coreData.folder.value)
	}
	try list := readCoreList(cores.files[cores.fileGui.Value])
	catch as e
		return MsgBox("Could not read the log sheet:`n`n" . e.Message)
	loadCoreRows(list.rows, list.customer)
}

; an .xlsx is a zip of xml files, tar.exe comes with windows 10 and newer
readCoreList(path) {
	tmp := A_Temp . "\easyQC_logsheet"
	try DirDelete(tmp, true)
	DirCreate(tmp)
	try {
		RunWait(Format('"{}\System32\tar.exe" -xf "{}" -C "{}" xl/workbook.xml xl/_rels xl/sharedStrings.xml xl/worksheets',
			A_WinDir, path, tmp),, "Hide")
		if !FileExist(tmp . "\xl\workbook.xml")
			throw Error("Couldn't open " . path . "`n`nIf it's still syncing from OneDrive, wait a moment and try again.")
		return readCoreXml(tmp . "\xl\")
	} finally {
		try DirDelete(tmp, true)
	}
}

; reads the values excel last saved for config!D24# (order, upc, roll, qty) from an unzipped log sheet
readCoreXml(dir) {
	workbook := loadXml(dir . "workbook.xml")
	rels := loadXml(dir . "_rels\workbook.xml.rels")
	strings := FileExist(dir . "sharedStrings.xml") ? loadXml(dir . "sharedStrings.xml").selectNodes("/x:sst/x:si") : ""

	sheet := loadXml(sheetFile(dir, workbook, rels, "config"))
	spill := sheet.selectSingleNode("//x:c[@r='D24']/x:f/@ref")
	if (!spill || !RegExMatch(spill.text, "^D24:G(\d+)$", &match))
		throw Error("No core label list in this log sheet (config!D24# is empty or missing).")

	rows := []
	columns := Map("D", 1, "E", 2, "F", 3, "G", 4)
	for rowNode in sheet.selectNodes("/x:worksheet/x:sheetData/x:row[@r >= 24 and @r <= " . match[1] . "]") {
		row := ["", "", "", ""]
		for cell in rowNode.selectNodes("x:c")
			if columns.Has(col := RegExReplace(cell.getAttribute("r"), "\d"))
				row[columns[col]] := cellText(cell, strings)
		rows.Push(row)
	}

	customer := ""
	try customer := definedNameText(dir, workbook, rels, strings, "order_customer")
	return { rows: rows, customer: customer }
}

; the value of a single cell name like order_customer ('Production Planner'!$A$3)
definedNameText(dir, workbook, rels, strings, name) {
	ref := workbook.selectSingleNode("/x:workbook/x:definedNames/x:definedName[@name='" . name . "']")
	if (!ref || !RegExMatch(ref.text, "^'?(.+?)'?!\$?([A-Z]+)\$?(\d+)$", &match))
		return ""
	sheet := loadXml(sheetFile(dir, workbook, rels, match[1]))
	cell := sheet.selectSingleNode(Format("/x:worksheet/x:sheetData/x:row[@r={2}]/x:c[@r='{1}{2}']", match[2], match[3]))
	return cell ? cellText(cell, strings) : ""
}

sheetFile(dir, workbook, rels, name) {
	sheet := workbook.selectSingleNode("/x:workbook/x:sheets/x:sheet[@name='" . name . "']")
	if !sheet
		throw Error("This file has no '" . name . "' sheet, is it a log sheet?")
	rel := rels.selectSingleNode("/p:Relationships/p:Relationship[@Id='" . sheet.selectSingleNode("@r:id").text . "']")
	target := StrReplace(rel.getAttribute("Target"), "/", "\")
	return (SubStr(target, 1, 1) == "\") ? dir . "..\" . SubStr(target, 2) : dir . target
}

; the value excel saved in a cell, text cells (t="s") point into sharedStrings.xml
cellText(cell, strings) {
	type := cell.getAttribute("t")
	if (type == "inlineStr")
		return (inline := cell.selectSingleNode("x:is")) ? inline.text : ""
	value := cell.selectSingleNode("x:v")
	if (!value || type == "e")
		return ""
	return (type == "s" && strings) ? strings.item(Integer(value.text)).text : value.text
}

loadXml(file) {
	doc := ComObject("Msxml2.DOMDocument.6.0")
	doc.async := false
	doc.setProperty("SelectionNamespaces", "xmlns:x='http://schemas.openxmlformats.org/spreadsheetml/2006/main' "
		. "xmlns:r='http://schemas.openxmlformats.org/officeDocument/2006/relationships' "
		. "xmlns:p='http://schemas.openxmlformats.org/package/2006/relationships'")
	if !doc.load(file)
		throw Error("Couldn't read " . file . "`n" . doc.parseError.reason)
	return doc
}

; values are the config!D24# rows: [order, upc, roll, qty]
loadCoreRows(values, customer) {
	cores.rows := []
	keyCounts := Map()
	for i, cells in values {
		row := {
			order: cleanCell(cells[1]),
			upc: cleanCell(cells[2], 12),
			roll: cleanCell(cells[3]),
			qty: cleanCell(cells[4]),
		}
		; key used to remember sent rolls, a repeated upc + roll gets a counter
		key := row.upc . "-" . row.roll
		keyCounts[key] := keyCounts.Get(key, 0) + 1
		row.key := keyCounts[key] > 1 ? key . "#" . keyCounts[key] : key
		cores.rows.Push(row)
	}
	if (cores.rows.Length == 0)
		return MsgBox("The core label list (config!D24#) is empty.")

	cores.order := cores.rows[1].order
	cores.customer := cleanCell(customer)
	if (cores.customer == "0")
		cores.customer := ""
	cores.current := 0
	cores.sentStack := []
	setCoresPaused(false)

	lv := cores.listGui
	lv.Opt("-Redraw")
	lv.Delete()
	for i, row in cores.rows {
		sent := IniRead("config.ini", coresSection(), row.key, "")
		lv.Add(sent == "" ? "Check" : "", "", row.upc, row.roll, row.qty, sentText(sent))
	}
	lv.Opt("+Redraw")
	cores.infoGui.Value := Format("{}   {}   {} rolls", cores.order, cores.customer, cores.rows.Length)
	updateCoresStatus()
}

; excel gives numbers as floats and may have commas/whitespace, digits pads upcs that lost leading zeros
cleanCell(value, digits := 0) {
	if IsObject(value) ; excel error values like #N/A
		return ""
	value := Trim(StrReplace(value, ",", ""), " `t`r`n")
	if IsNumber(value)
		value := String(Round(value))
	if (digits && RegExMatch(value, "^\d+$") && StrLen(value) < digits)
		value := Format("{:0" . digits . "d}", Integer(value))
	return value
}

coresSection() => "cores_" . cores.order

onCoresDoubleClick(lv, rowNum) {
	if (rowNum == 0)
		return
	flushLogoClick()
	writeCoreRoll(rowNum)
}

onCoresStart(*) {
	flushLogoClick()
	first := cores.listGui.GetNext(0, "Checked")
	if (first == 0)
		return MsgBox(cores.rows.Length ? "No rolls are checked." : "Load a log sheet first.")
	if (coreData.logoX2.value == "")
		MsgBox("The b&g logo area isn't set, so easyQC can't tell when you click the logo.`n`nPress 'set logo area' first, or double-click each roll yourself before clicking the logo.")

	cores.sentStack := []
	setCoresPaused(false)
	writeCoreRoll(first)
}

onCoresBack(*) {
	flushLogoClick()
	if (cores.sentStack.Length == 0)
		return statusBar.SetText("Nothing to go back to yet")
	writeCoreRoll(cores.sentStack.Pop())
}

onCoresPause(*) {
	flushLogoClick()
	setCoresPaused(!cores.paused)
	if (!cores.paused && cores.current)
		writeCoreRoll(cores.current) ; the csv may have been changed from the label tab while paused
	updateCoresStatus()
}

setCoresPaused(paused) {
	cores.paused := paused
	cores.pauseButton.Text := paused ? "resume" : "pause"
}

writeCoreRoll(rowNum) {
	if (coreData.initials.gui.value == "") {
		MsgBox("Type your initials in QC By first.")
		return false
	}
	row := cores.rows[rowNum]
	values := { order: row.order, upc: row.upc, initials: coreData.initials.gui.value, date: getDate(),
		roll: row.roll, quantity: row.qty, customer: cores.customer }
	for key, value in values.OwnProps() {
		labelData.%key%.gui.value := value
		saveItem(labelData.%key%)
	}
	if !onWrite()
		return false

	clearCurrentCore()
	cores.current := rowNum
	cores.listGui.Modify(rowNum, "Check Vis", "►")
	updateCoresStatus()
	return true
}

clearCurrentCore() {
	if (cores.current)
		cores.listGui.Modify(cores.current, "", "")
	cores.current := 0
}

markCoreSent(rowNum) {
	sent := coreData.initials.gui.value . " " . A_Now
	IniWrite(sent, "config.ini", coresSection(), cores.rows[rowNum].key)
	cores.listGui.Modify(rowNum, "-Check Col5", sentText(sent))
}

; sent rolls are saved as "<initials> <A_Now>", shown with the time if sent today, otherwise the date
sentText(sent) {
	if !RegExMatch(sent, "^(\S*) (\d{14})$", &match)
		return sent
	isToday := SubStr(match[2], 1, 8) == SubStr(A_Now, 1, 8)
	return match[1] . " " . (isToday ? StrLower(FormatTime(match[2], "h:mmt")) : FormatTime(match[2], "M/d"))
}

onCoresClick() {
	CoordMode("Mouse", "Screen")
	MouseGetPos(&x, &y, &win)
	if !isOverLogo(x, y, win)
		return
	; wait for the b&g program to read the csv before writing the next roll, a second click restarts the wait
	cores.pendingClick := true
	SetTimer(onLogoPrinted, -(IsInteger(coreData.delay.value) ? coreData.delay.value : 1500))
}

onLogoPrinted() {
	cores.pendingClick := false
	if (!cores.current)
		return
	markCoreSent(cores.current)
	cores.sentStack.Push(cores.current)

	next := cores.listGui.GetNext(cores.current, "Checked")
	if (next == 0)
		next := cores.listGui.GetNext(0, "Checked") ; checked rows above the current one
	if (next == 0) {
		clearCurrentCore()
		return updateCoresStatus()
	}
	writeCoreRoll(next)
}

; handle a logo click that is still waiting on its delay before the user changes anything
flushLogoClick() {
	if (!cores.pendingClick)
		return
	SetTimer(onLogoPrinted, 0)
	onLogoPrinted()
}

isOverLogo(x, y, win) {
	if (coreData.logoX2.value == "" || win == myGui.Hwnd)
		return false
	try {
		if (coreData.logoClass.value != "" && WinGetClass(win) != coreData.logoClass.value)
			return false
		if (coreData.logoExe.value != "" && WinGetProcessName(win) != coreData.logoExe.value)
			return false
		WinGetPos(&winX, &winY,,, win)
	} catch
		return false
	x -= winX, y -= winY
	return (x >= coreData.logoX1.value && x <= coreData.logoX2.value
		&& y >= coreData.logoY1.value && y <= coreData.logoY2.value)
}

updateCoresStatus() {
	if (Tab.value != cores.tabNum)
		return
	if (!cores.current) {
		msg := tabStatusMessages[cores.tabNum]
		if (cores.rows.Length)
			msg := cores.listGui.GetNext(0, "Checked") ? "Check the rolls to print, then press start" : "No checked rolls left"
		return statusBar.SetText(msg)
	}
	left := 0, i := 0
	while (i := cores.listGui.GetNext(i, "Checked"))
		left++
	row := cores.rows[cores.current]
	statusBar.SetText(Format("{}{} roll {} ready, click logo ({} left)",
		cores.paused ? "PAUSED " : "", SubStr(row.upc, -4), row.roll, left))
}

; the logo area is found by hovering instead of clicking, since clicking the logo prints
onCoresSetLogo(*) {
	cores.logoStep := 1
	cores.logoCountdown := 3
	SetTimer(logoCountdownTick, 1000)
	logoCountdownTick()
}

logoCountdownTick() {
	corner := (cores.logoStep == 1) ? "TOP-LEFT" : "BOTTOM-RIGHT"
	if (cores.logoCountdown > 0) {
		ToolTip("Hold the mouse over the " . corner . " corner of the b&g logo`n(don't click it)   " . cores.logoCountdown)
		cores.logoCountdown -= 1
		return
	}
	ToolTip()
	CoordMode("Mouse", "Screen")
	MouseGetPos(&x, &y, &win)
	try WinGetPos(&winX, &winY,,, win)
	catch {
		SetTimer(logoCountdownTick, 0)
		return MsgBox("Couldn't read the window under the mouse, try again.")
	}
	if (win == myGui.Hwnd) {
		SetTimer(logoCountdownTick, 0)
		return MsgBox("That was easyQC's window, hold the mouse over the b&g logo instead.")
	}
	x -= winX, y -= winY

	if (cores.logoStep == 1) {
		cores.logoCorner := { win: win, x: x, y: y }
		cores.logoStep := 2
		cores.logoCountdown := 3
		return logoCountdownTick()
	}
	SetTimer(logoCountdownTick, 0)
	if (win != cores.logoCorner.win)
		return MsgBox("The two corners were on different windows, try again.")

	exe := "", cls := "", title := "", pid := 0
	try exe := WinGetProcessName(win)
	try cls := WinGetClass(win)
	try title := WinGetTitle(win)
	try pid := WinGetPID(win)
	values := { logoExe: exe, logoClass: cls,
		logoX1: Min(x, cores.logoCorner.x), logoY1: Min(y, cores.logoCorner.y),
		logoX2: Max(x, cores.logoCorner.x), logoY2: Max(y, cores.logoCorner.y) }
	for key, value in values.OwnProps() {
		coreData.%key%.value := value
		IniWrite(value, "config.ini", "cores", key)
	}
	updateLogoText()

	msg := Format("Logo area saved ({} x {} px)`n`n{}`nahk_exe {}`nahk_class {}",
		values.logoX2 - values.logoX1, values.logoY2 - values.logoY1, title, exe, cls)
	if (!A_IsAdmin && isElevated(pid) == 1)
		msg .= "`n`nThe b&g program is running as administrator, so easyQC can't see clicks on it. Close easyQC and run it as administrator too (right-click > Run as administrator)."
	MsgBox(msg)
}

updateLogoText() {
	if (coreData.logoX2.value == "")
		cores.logoGui.Value := "logo area not set"
	else
		cores.logoGui.Value := "logo area set (" . coreData.logoExe.value . ")"
}

; 1 if the process runs as admin, 0 if not, -1 if unknown
isElevated(pid) {
	elevated := -1
	if !(hProcess := DllCall("OpenProcess", "UInt", 0x1000, "Int", false, "UInt", pid, "Ptr")) ; PROCESS_QUERY_LIMITED_INFORMATION
		return elevated
	if DllCall("advapi32\OpenProcessToken", "Ptr", hProcess, "UInt", 0x8, "Ptr*", &hToken := 0) { ; TOKEN_QUERY
		if DllCall("advapi32\GetTokenInformation", "Ptr", hToken, "Int", 20, "UInt*", &tokenElevated := 0, "UInt", 4, "UInt*", &size := 0) ; TokenElevation
			elevated := tokenElevated
		DllCall("CloseHandle", "Ptr", hToken)
	}
	DllCall("CloseHandle", "Ptr", hProcess)
	return elevated
}

changeCounter(item, direction, counterDigits := 3) {
	txtPart := SubStr(item.gui.Value, 1, -1 * counterDigits)
	numPart := SubStr(item.gui.Value,    -1 * counterDigits)
	if(!isNumber(numPart))
		return

	num := Number(numPart) + (direction == "up" ? 1 : -1)
	switch {
		case num               >= 1000: numPart := "001"
		case num < 1000 && num >=  100: numPart := String(num)
		case num <  100 && num >=   10: numPart := "0" . String(num)
		case num <   10 && num >=    1: numPart := "00" . String(num)
		case num <    1               : numPart := "999"
	}

	item.gui.value := txtPart . numPart
	saveItem(item)
}

changeDate(item, direction, delimiter := "/") {
    dlm := delimiter

	if !RegExMatch(item.gui.value, "^\d\d?" . dlm . "\d\d?" . dlm . "\d\d\d?\d?$") {
		return 
	}
	dates := StrSplit(item.gui.value, dlm)
	month := dates[1], day := dates[2], year := dates[3]
	if (day == '0' || day == '00' || month == '0' || month == '00') {
		return
	}

	mFormat := "MM", dFormat := "dd", yFormat := "yyyy"
	if StrLen(month) == 1 {
		month := '0' . month
		mFormat := "M"
	}
	if StrLen(day) == 1 {
		day := '0' . day
		dFormat := "d"
	}
	if StrLen(year) == 2 {
		year := '20' . year
		yFormat := "yy"
	}
	if StrLen(month) != 2 || StrLen(day) !== 2 || StrLen(year) != 4 {
		return
	}
	format := mFormat . dlm . dFormat . dlm . yFormat

	newDate := FormatTime(DateAdd(year . month . day, (direction == "up" ? 1 : -1), "days"), format)
	item.gui.value := newDate
	saveItem(item)
}

formatOptions(obj) {
	str := "" 
	if (obj.HasProp("xPrev"))
		str .= "xp" . "+" . obj.xPrev . " "
	if (obj.HasProp("yPrev"))
		str .= "yp" . "+" . obj.yPrev . " "
	if (obj.HasProp("xSection"))
		str .= "xs" . "+" . obj.xSection . " "
	if (obj.HasProp("ySection")) 
		str .= "ys" . ((obj.ySection >= 0) ? "+" : "") . obj.ySection . " "
	if (obj.HasProp("xMargin"))
		str .= "xm" . "+" . obj.xMargin . " "
	if (obj.HasProp("yMargin")) 
		str .= "ym" . obj.yMargin . " "

	if (obj.HasProp("justify"))
		str .= obj.justify . " "
	if (obj.HasProp("noWrap"))
		str .= "-Wrap "
	if (obj.HasProp("noMulti"))
		str .= "-Multi r1 "
	
	if (obj.HasProp("width"))
		str .= "w" . obj.width . " "
	if (obj.HasProp("height"))
		str .= "h" . obj.height . " "

	if (obj.HasProp("newSection") && obj.newSection)
		str .= "Section" . " "

	if (obj.HasProp("background"))
		str .= "background" . obj.background . " "
	if (obj.HasProp("charLimit"))
		str .= "limit" . obj.charLimit . " "
	if (obj.HasProp("uppercase") && obj.uppercase)
		str .= "Uppercase" . " "
	if (obj.HasProp("number"))
		str .= "number" . " "
	if (obj.HasProp("center") && obj.center)
		str .= "center" . " "
	if(obj.HasProp("fontSize"))
		str .= "s" . obj.fontSize . " "
	if (obj.HasProp("foreground"))
		str .= "c" . obj.foreground . " "
	if (obj.HasProp("bold") && obj.bold)
		str .= "bold" . " "
	if (obj.HasProp("checked") && obj.checked == 1)
		str .= "checked" . " "
	if (obj.HasProp("stopTab") && obj.stopTab == true)
		str .= "-TabStop" . " "

	return str
}

; =======================================================================================
; ====================================== HOTKEYS ========================================
; =======================================================================================

MouseIsOver(WinTitle) {
    MouseGetPos ,, &Win
    return WinExist(WinTitle " ahk_id " Win)
}

#HotIf MouseIsOver("ahk_exe AutoHotkey64.exe")

~WheelUp:: onWheel("up")
~WheelDown:: onWheel("down")
onWheel(direction) {
	if(settings.autoLabelDate.gui.value = 1) {
		return
	}
	MouseGetPos(,,, &controlClassNN)
	switch controlClassNN {
		case labelData.date.gui.ClassNN:      changeDate(labelData.date, direction, "/")
		case sampleData.date.gui.ClassNN:     changeDate(sampleData.date, direction, "-")
		case sampleData.customer.gui.ClassNN: changeCounter(sampleData.customer, direction)
	} 
	Sleep(30) ;; limit script
}

#HotIf cores.current && !cores.paused
~LButton Up:: onCoresClick()

#HotIf exeActive("cmd.exe", "WindowsTerminal.exe", "emacs.exe", "sublime_text.exe", paths.rfid_file.gui.value) or classActive("Notepad")
^1::onPrint()
^2::onSamplePrint()

onPrint(*) {
	if (Tab.value != 1)
		return

	if (data.order.gui.Visible && !data.preOrder.gui.Visible && !data.postOrder.gui.Visible)
		order := data.order.gui.value
	else if (!data.order.gui.Visible && data.preOrder.gui.Visible && data.postOrder.gui.Visible)
		order := data.preOrder.gui.value . data.postOrder.gui.value
	else
		return MsgBox("error parsing order number, something messed up")

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

	status := [0,0,0,0,0,0,0,0,0]
	status[1] := inputDataAndSleep(data.initials.gui.value)
	status[2] := inputDataAndSleep(data.customer.gui.value)
	status[3] := inputDataAndSleep(order)
	status[4] := inputDataAndSleep(data.upc.gui.value)
	status[5] := inputDataAndSleep(data.style.gui.value)
	status[6] := inputDataAndSleep(data.roll.gui.value)
	status[7] := inputDataAndSleep("Y")
	status[8] := inputDataAndSleep("N")
	status[9] := inputDataAndSleep("Y")

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

    for index, value in status {
		if !value
			return
    }
	updatePrevValues(data)
	saveHistory(order)
}

onSamplePrint(*) {
	if (Tab.value != 2) {
		return
	}

	sampleStyleText := sampleData.style.gui.Text

	if (settings.qc4Toggle.gui.value) {
		; TODO: Add Roll ID for qc4 chagne
	}

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

	status := [0,0,0,0,0,0,0,0,0]
	status[1] := inputDataAndSleep(sampleData.initials.gui.value)
	status[2] := inputDataAndSleep(sampleData.customer.gui.value)
	status[3] := inputDataAndSleep(sampleData.order.gui.value . sampleData.date.gui.value)
	status[4] := inputDataAndSleep("") ; No upc
	status[5] := inputDataAndSleep(sampleStyleText) ; TODO: verify text works
	status[6] := inputDataAndSleep(sampleData.roll.gui.value)
	status[7] := inputDataAndSleep("Y")
	status[8] := inputDataAndSleep("N")
	status[9] := inputDataAndSleep("Y")

	Send("{Ctrl down}") ; todo: verify this fix works for ctrl key getting stuck
	Send("{Ctrl up}")

    for index, value in status {
		if !value
			return
    }
	updatePrevValues(sampleData)
}

inputDataAndSleep(obj) {
	if !exeActive("cmd.exe", "WindowsTerminal.exe", "emacs.exe", "sublime_text.exe", paths.rfid_file.gui.value)
		&& !classActive("Notepad") {
		return 0
	}
	SendInput(obj . "{enter}")
	Sleep(settings.delay.gui.value)
	return 1
}

exeActive(params*) {
	for index, exe in params
	if (WinActive("ahk_exe " . exe))
		return true
	return false
}
classActive(params*) {
	for index, cls in params
	if (WinActive("ahk_class " . cls))
		return true
	return false
}

; =======================================================================================
; ======================================= DEBUG ========================================
; =======================================================================================
out(obj) {
	if(Type(obj) == "Array") {
		s := "arr:`n"
		Loop obj.Length
			s .= "  • " (IsObject(obj[A_Index]) ? reduceToStrings(obj[A_Index]) : String(obj[A_Index])) "`n"
	    return OutputDebug(s)
	}
	if (!IsObject(obj)) {
		return OutputDebug(obj)
	}
	s := "obj:`n"
	for key, value in obj.OwnProps() {
		s .= "  •" key " = " (IsObject(value) ? reduceToStrings(value) : String(value)) "`n"
	}
	OutputDebug(s)
}

reduceToStrings(obj) {
	if (!isObject(obj))
		return obj
	s := "{ "
	for key, value in obj.OwnProps() {
		s .= key " = " reduceToStrings(value) " , "
	}
	return SubStr(s, 1, -2) "}"
}

if(devMode)
	OutputDebug("`n    ")
