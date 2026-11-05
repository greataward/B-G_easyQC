A gui app that simplifies the Quality Control process for a company I work at while adding more functionality.

## Cores tab (core labels)

Fills the b&g core label csv straight from the order's log sheet, using the `config!D24#` list (order, upc, roll, qty). Excel isn't needed: easyQC reads the log sheet files from the OneDrive synced SharePoint folder (using `tar.exe` and MSXML, which come with Windows 10 and 11).

1. Go to the **Cores** tab, pick the log sheet (newest changed first) and press **load**.
2. Type your initials in **QC By**, uncheck any rolls you don't need, then press **start**.
3. Click the b&g logo to print. About 1.5 seconds after each click easyQC marks that roll as sent and writes the next checked roll, so just keep clicking the logo.

- **↻** searches the folder again (do this to see log sheets added since easyQC started)
- the **all** box checks or unchecks every roll at once (it's gray when only some are checked)
- **double-click** a roll to write only that roll (e.g. to reprint it with your initials)
- **back** writes the previous roll again so the next logo click reprints it
- **pause** ignores logo clicks until you press **resume**
- sent rolls are remembered per order in `config.ini` and start unchecked the next time the order is loaded

**First time setup:**
- press **…** and choose the synced `000-Orders` folder in File Explorer. Every `Log Sheet` .xlsx in its customer and order folders is listed, newest changed first
- press **set logo area** and hold the mouse (don't click) over the top-left corner of the b&g logo, then the bottom-right corner when asked. The status bar says "Logo click seen" for each click on the logo. If the b&g program runs as administrator, Windows hides those clicks from easyQC, so easyQC offers to restart itself as administrator (when setting the logo area and when pressing **start**).

The roll list is what Excel last saved in the log sheet, so save any changes in Excel and let OneDrive sync before loading. The wait after a logo click can be changed with `delay=` (ms) under `[cores]` in `config.ini`.
