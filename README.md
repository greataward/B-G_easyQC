A gui app that simplifies the Quality Control process for a company I work at while adding more functionality.

## Cores tab (core labels)

Fills the b&g core label csv straight from the order's log sheet, using the `config!D24#` list (order, upc, roll, qty).

1. Open the order's log sheet in Excel, go to the **Cores** tab, pick the log sheet and press **load**.
2. Type your initials in **QC By**, uncheck any rolls you don't need, then press **start**.
3. Click the b&g logo to print. About 1.5 seconds after each click easyQC marks that roll as sent and writes the next checked roll, so just keep clicking the logo.

- **double-click** a roll to write only that roll (e.g. to reprint it with your initials)
- **back** writes the previous roll again so the next logo click reprints it
- **pause** ignores logo clicks until you press **resume**
- sent rolls are remembered per order in `config.ini` and start unchecked the next time the order is loaded

**First time setup:** press **set logo area** and hold the mouse (don't click) over the top-left corner of the b&g logo, then the bottom-right corner when asked. If logo clicks are ignored afterwards, the b&g program is probably running as administrator, so run easyQC as administrator too.

The wait after a logo click can be changed with `delay=` (ms) under `[cores]` in `config.ini`.
