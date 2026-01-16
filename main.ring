# The Main File
load "package.ring"
load "lib.ring"
load "src/utils/color.ring"

func main
    nInnerWidth = 47
    cHLine = copy("─", nInnerWidth)
    
    banner = []
    banner[:topBorder] = colorText([:text = "╭" + cHLine + "╮", :color = :BRIGHT_BLUE, :style = :BOLD])
    banner[:tEmptyLine] = colorText([:text = "│" + space(nInnerWidth) + "│", :color = :BRIGHT_BLUE])
    
    # Title
    cName = "WebView"
    nTitleVisualWidth = 2 + 2 + len(cName)  # ★ + space + name + space + ★
    nTitlePad = floor((nInnerWidth - nTitleVisualWidth) / 2)
    nTitlePadRight = nInnerWidth - nTitleVisualWidth - nTitlePad
    banner[:titleLine] = colorText([:text = "│" + space(nTitlePad), :color = :BRIGHT_BLUE]) + 
                         colorText([:text = cSymbols[:STAR] + " " + cName + " " + cSymbols[:STAR], :color = :CYAN, :style = :BOLD]) + 
                         colorText([:text = space(nTitlePadRight) + "│", :color = :BRIGHT_BLUE])
    
    banner[:tEmptyLine2] = colorText([:text = "│" + space(nInnerWidth) + "│", :color = :BRIGHT_BLUE])
    
    # Version line
    cVersionStr = "v" + aPackageInfo[:version]
    nVersionPad = floor((nInnerWidth - len(cVersionStr)) / 2)
    nVersionPadRight = nInnerWidth - len(cVersionStr) - nVersionPad
    banner[:versionLine] = colorText([:text = "│" + space(nVersionPad), :color = :BRIGHT_BLUE]) + 
                           colorText([:text = cVersionStr, :color = :YELLOW, :style = :BOLD]) + 
                           colorText([:text = space(nVersionPadRight) + "│", :color = :BRIGHT_BLUE])
    
   
    banner[:tEmptyLine3] = colorText([:text = "│" + space(nInnerWidth) + "│", :color = :BRIGHT_BLUE])
    # Separator
    nSepPad = 5
    nDotsCount = nInnerWidth - (nSepPad * 2)
    banner[:separator] = colorText([:text = "│" + space(nSepPad), :color = :BRIGHT_BLUE]) + 
                         colorText([:text = copy("·", nDotsCount), :color = :WHITE, :style = :DIM]) + 
                         colorText([:text = space(nSepPad) + "│", :color = :BRIGHT_BLUE])
    
    banner[:bEmptyLine4] = colorText([:text = "│" + space(nInnerWidth) + "│", :color = :BRIGHT_BLUE])
    # Author line
    cAuthorText = "Made with  by ysdragon"
    nAuthorVisualWidth = len(cAuthorText) + 1
    nAuthorPad = floor((nInnerWidth - nAuthorVisualWidth) / 2)
    nAuthorPadRight = nInnerWidth - nAuthorVisualWidth - nAuthorPad
    banner[:authorLine] = colorText([:text = "│" + space(nAuthorPad), :color = :BRIGHT_BLUE]) + 
                          colorText([:text = "Made with ", :color = :WHITE, :style = :DIM]) + 
                          colorText([:text = cSymbols[:HEART], :color = :BRIGHT_RED]) + 
                          colorText([:text = " by ", :color = :WHITE, :style = :DIM]) + 
                          colorText([:text = "ysdragon", :color = :MAGENTA]) + 
                          colorText([:text = space(nAuthorPadRight) + "│", :color = :BRIGHT_BLUE])
    
    banner[:bEmptyLine5] = colorText([:text = "│" + space(nInnerWidth) + "│", :color = :BRIGHT_BLUE])
    # URL line
    cUrlStr = "https://github.com/ysdragon"
    nUrlPad = floor((nInnerWidth - len(cUrlStr)) / 2)
    nUrlPadRight = nInnerWidth - len(cUrlStr) - nUrlPad
    banner[:urlLine] = colorText([:text = "│" + space(nUrlPad), :color = :BRIGHT_BLUE]) + 
                       colorText([:text = cUrlStr, :color = :GREEN, :style = :UNDERLINE]) + 
                       colorText([:text = space(nUrlPadRight) + "│", :color = :BRIGHT_BLUE])
    
    banner[:bEmptyLine6] = colorText([:text = "│" + space(nInnerWidth) + "│", :color = :BRIGHT_BLUE])
    banner[:bottomBorder] = colorText([:text = "╰" + cHLine + "╯", :color = :BRIGHT_BLUE, :style = :BOLD])
    
    ? ""
    for line in banner
        ? "  " + line[2]
    next
    ? ""
