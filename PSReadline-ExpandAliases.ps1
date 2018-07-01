# Add this code to your $PROFILE

# PSReadline custom keybinds
if ($host.Name -eq 'ConsoleHost') {
    # Binds Ctrl+e to expand aliases
    $ScriptBlock = {
        param($key, $arg)
        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$ast,
            [ref]$tokens,
            [ref]$errors,
            [ref]$cursor
        )
        $startAdjustment = 0
        foreach ($token in $tokens) {
            if ($token.TokenFlags -band [System.Management.Automation.Language.TokenFlags]::CommandName) {
                $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
                if ($alias -ne $null) {
                    $resolvedCommand = $alias.Definition
                    if ($resolvedCommand -ne $null) {
                        $extent = $token.Extent
                        $length = $extent.EndOffset - $extent.StartOffset
                        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                            $extent.StartOffset + $startAdjustment,
                            $length,
                            $resolvedCommand
                        )
                        $startAdjustment += ($resolvedCommand.Length - $length)
                    }
                }
            }
        }
    }
    $Params = @{
        Chord            = 'Ctrl+e'
        BriefDescription = 'ExpandAliases'
        LongDescription  = 'Replace all aliases with the full command'
        ScriptBlock      = $ScriptBlock
    }
    Set-PSReadlineKeyHandler @Params
}
