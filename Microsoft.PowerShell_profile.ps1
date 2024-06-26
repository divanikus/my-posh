# function prompt {
#     $Success = $?
#     $user = [Security.Principal.WindowsIdentity]::GetCurrent()
#     $isAdmin = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

#     Switch ((get-location).provider.name) {
#         "FileSystem" { $fg = "yellow"}
#         "Registry" { $fg = "magenta"}
#         "wsman" { $fg = "cyan"}
#         "Environment" { $fg = "green"}
#         "Certificate" { $fg = "darkcyan"}
#         "Function" { $fg = "gray"}
#         "alias" { $fg = "darkgray"}
#         "variable" { $fg = "darkgreen"}
#         Default { $fg = $host.ui.rawui.ForegroundColor}
#     } 

#     ## Path
#     $Drive = $pwd.Drive.Name
#     $Pwds = $pwd -split "\\" | Where-Object { -Not [String]::IsNullOrEmpty($_) }
#     $PwdPath = if ($Pwds.Count -gt 3) {
#         $Pre = $Pwds[1..($Pwds.Count-3)] | ForEach-Object{ $_.substring(0, 1) }
#         "$($Pre  -join "\")\$($Pwds[-2])\$($Pwds[-1])"
#     }
#     elseif ($Pwds.Count -eq 3) {
#         $Pwds[1..2] -join "\"
#     }
#     elseif ($Pwds.Count -eq 2) {
#         $Pwds[1]
#     }
#     else { "" }

#     Write-Host "[$(Get-Date -Format ‘HH:mm:ss’)] " -ForegroundColor "darkgray" -NoNewline
#     Write-Host "PS " -NoNewline -ForegroundColor ($isAdmin ? "White" : "Blue")
#     Write-Host $env:username -nonewline -ForegroundColor ($isAdmin ? "Red" : "Green")
#     Write-Host "@" -nonewline -ForegroundColor "yellow"
#     Write-Host $env:computername -nonewline -ForegroundColor "cyan"
#     Write-Host " $Drive`:\$PwdPath " -foregroundcolor $fg -nonewline
#     Write-Host "$('>' * ($nestedPromptLevel + 1))" -ForegroundColor ($Success ? "darkgray" : "Red") -NoNewline
#     Write-Output " "
# }

oh-my-posh init pwsh --config 'C:\Users\Andrey\posh.json' | Invoke-Expression
Import-Module -Name Terminal-Icons
Set-PSReadlineKeyHandler -Key ctrl+d -Function ViExit
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

#34de4b3d-13a8-4540-b76d-b9e8d3851756 PowerToys CommandNotFound module

Import-Module "C:\Program Files\PowerToys\WinUI3Apps\..\WinGetCommandNotFound.psd1"
#34de4b3d-13a8-4540-b76d-b9e8d3851756

function has_prefix {
        param (
                [string]$prefix,
                [string]$string
        )

        if ($string.StartsWith($prefix)) {
                return $true
        } else {
                return $false
        }
}

function kubeswitch {

        #You need to have switcher_windows_amd64.exe in your PATH, or you need to change the value of EXECUTABLE_PATH here
        $EXECUTABLE_PATH = "switcher.exe"

        if (-not $args) {
        Write-Output "no options provided"
                Write-Output $EXECUTABLE_PATH $args
                $RESPONSE = & $EXECUTABLE_PATH
        }
        else{
        Write-Output "options provided:" $args
                        Write-Output $EXECUTABLE_PATH $args
                $RESPONSE = & $EXECUTABLE_PATH  $args
        }

        if ($LASTEXITCODE -ne 0 -or -not $RESPONSE) {
                Write-Output $RESPONSE
                return $LASTEXITCODE
        }

        # switcher returns a response that contains a kubeconfig path with a prefix "__ " to be able to
        # distinguish it from other responses which just need to write to STDOUT
        $prefix = "__ "
        if (-not (has_prefix $prefix $RESPONSE)) {
                Write-Output $RESPONSE
                return
        }


        $RESPONSE = $RESPONSE -replace $prefix, ""
        Write-Output $RESPONSE
        $remainder = $RESPONSE
        Write-Output $remainder
        Write-Output $remainder.split(",")[0]
        Write-Output $remainder.split(",")[1]
        $KUBECONFIG_PATH = $remainder.split(",")[0]
        $KUBECONFIG_PATH = $KUBECONFIG_PATH -replace '\\', '/'
        $KUBECONFIG_PATH = $KUBECONFIG_PATH -replace "C:", ""
        Write-Output $KUBECONFIG_PATH
        $SELECTED_CONTEXT = $remainder.split(",")[1]

        if (-not $KUBECONFIG_PATH) {
                Write-Output $RESPONSE
                return
        }

        if (-not $SELECTED_CONTEXT) {
                Write-Output $RESPONSE
                return
        }

        $switchTmpDirectory = "$env:USERPROFILE\.kube\.switch_tmp\config"
        if ($env:KUBECONFIG -and $env:KUBECONFIG -like "*$switchTmpDirectory*") {
                Remove-Item -Path $env:KUBECONFIG -Force
        }

        $env:KUBECONFIG = $KUBECONFIG_PATH
        Write-Output "switched to context $SELECTED_CONTEXT"
}

#Env variable HOME doesn't exist on windows, we create it from USERPROFILE
$Env:HOME = $Env:USERPROFILE

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# powershell completion for kubectl                              -*- shell-script -*-

function __kubectl_debug {
    if ($env:BASH_COMP_DEBUG_FILE) {
        "$args" | Out-File -Append -FilePath "$env:BASH_COMP_DEBUG_FILE"
    }
}

filter __kubectl_escapeStringWithSpecialChars {
    $_ -replace '\s|#|@|\$|;|,|''|\{|\}|\(|\)|"|`|\||<|>|&','`$&'
}

[scriptblock]$__kubectlCompleterBlock = {
    param(
            $WordToComplete,
            $CommandAst,
            $CursorPosition
        )

    # Get the current command line and convert into a string
    $Command = $CommandAst.CommandElements
    $Command = "$Command"

    __kubectl_debug ""
    __kubectl_debug "========= starting completion logic =========="
    __kubectl_debug "WordToComplete: $WordToComplete Command: $Command CursorPosition: $CursorPosition"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CursorPosition location, so we need
    # to truncate the command-line ($Command) up to the $CursorPosition location.
    # Make sure the $Command is longer then the $CursorPosition before we truncate.
    # This happens because the $Command does not include the last space.
    if ($Command.Length -gt $CursorPosition) {
        $Command=$Command.Substring(0,$CursorPosition)
    }
    __kubectl_debug "Truncated command: $Command"

    $ShellCompDirectiveError=1
    $ShellCompDirectiveNoSpace=2
    $ShellCompDirectiveNoFileComp=4
    $ShellCompDirectiveFilterFileExt=8
    $ShellCompDirectiveFilterDirs=16
    $ShellCompDirectiveKeepOrder=32

    # Prepare the command to request completions for the program.
    # Split the command at the first space to separate the program and arguments.
    $Program,$Arguments = $Command.Split(" ",2)

    $RequestComp="$Program __complete $Arguments"
    __kubectl_debug "RequestComp: $RequestComp"

    # we cannot use $WordToComplete because it
    # has the wrong values if the cursor was moved
    # so use the last argument
    if ($WordToComplete -ne "" ) {
        $WordToComplete = $Arguments.Split(" ")[-1]
    }
    __kubectl_debug "New WordToComplete: $WordToComplete"


    # Check for flag with equal sign
    $IsEqualFlag = ($WordToComplete -Like "--*=*" )
    if ( $IsEqualFlag ) {
        __kubectl_debug "Completing equal sign flag"
        # Remove the flag part
        $Flag,$WordToComplete = $WordToComplete.Split("=",2)
    }

    if ( $WordToComplete -eq "" -And ( -Not $IsEqualFlag )) {
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __kubectl_debug "Adding extra empty parameter"
        # PowerShell 7.2+ changed the way how the arguments are passed to executables,
        # so for pre-7.2 or when Legacy argument passing is enabled we need to use
        # `"`" to pass an empty argument, a "" or '' does not work!!!
        if ($PSVersionTable.PsVersion -lt [version]'7.2.0' -or
            ($PSVersionTable.PsVersion -lt [version]'7.3.0' -and -not [ExperimentalFeature]::IsEnabled("PSNativeCommandArgumentPassing")) -or
            (($PSVersionTable.PsVersion -ge [version]'7.3.0' -or [ExperimentalFeature]::IsEnabled("PSNativeCommandArgumentPassing")) -and
              $PSNativeCommandArgumentPassing -eq 'Legacy')) {
             $RequestComp="$RequestComp" + ' `"`"'
        } else {
             $RequestComp="$RequestComp" + ' ""'
        }
    }

    __kubectl_debug "Calling $RequestComp"
    # First disable ActiveHelp which is not supported for Powershell
    $env:KUBECTL_ACTIVE_HELP=0

    #call the command store the output in $out and redirect stderr and stdout to null
    # $Out is an array contains each line per element
    Invoke-Expression -OutVariable out "$RequestComp" 2>&1 | Out-Null

    # get directive from last line
    [int]$Directive = $Out[-1].TrimStart(':')
    if ($Directive -eq "") {
        # There is no directive specified
        $Directive = 0
    }
    __kubectl_debug "The completion directive is: $Directive"

    # remove directive (last element) from out
    $Out = $Out | Where-Object { $_ -ne $Out[-1] }
    __kubectl_debug "The completions are: $Out"

    if (($Directive -band $ShellCompDirectiveError) -ne 0 ) {
        # Error code.  No completion.
        __kubectl_debug "Received error from custom completion go code"
        return
    }

    $Longest = 0
    [Array]$Values = $Out | ForEach-Object {
        #Split the output in name and description
        $Name, $Description = $_.Split("`t",2)
        __kubectl_debug "Name: $Name Description: $Description"

        # Look for the longest completion so that we can format things nicely
        if ($Longest -lt $Name.Length) {
            $Longest = $Name.Length
        }

        # Set the description to a one space string if there is none set.
        # This is needed because the CompletionResult does not accept an empty string as argument
        if (-Not $Description) {
            $Description = " "
        }
        @{Name="$Name";Description="$Description"}
    }


    $Space = " "
    if (($Directive -band $ShellCompDirectiveNoSpace) -ne 0 ) {
        # remove the space here
        __kubectl_debug "ShellCompDirectiveNoSpace is called"
        $Space = ""
    }

    if ((($Directive -band $ShellCompDirectiveFilterFileExt) -ne 0 ) -or
       (($Directive -band $ShellCompDirectiveFilterDirs) -ne 0 ))  {
        __kubectl_debug "ShellCompDirectiveFilterFileExt ShellCompDirectiveFilterDirs are not supported"

        # return here to prevent the completion of the extensions
        return
    }

    $Values = $Values | Where-Object {
        # filter the result
        $_.Name -like "$WordToComplete*"

        # Join the flag back if we have an equal sign flag
        if ( $IsEqualFlag ) {
            __kubectl_debug "Join the equal sign flag back to the completion value"
            $_.Name = $Flag + "=" + $_.Name
        }
    }

    # we sort the values in ascending order by name if keep order isn't passed
    if (($Directive -band $ShellCompDirectiveKeepOrder) -eq 0 ) {
        $Values = $Values | Sort-Object -Property Name
    }

    if (($Directive -band $ShellCompDirectiveNoFileComp) -ne 0 ) {
        __kubectl_debug "ShellCompDirectiveNoFileComp is called"

        if ($Values.Length -eq 0) {
            # Just print an empty string here so the
            # shell does not start to complete paths.
            # We cannot use CompletionResult here because
            # it does not accept an empty string as argument.
            ""
            return
        }
    }

    # Get the current mode
    $Mode = (Get-PSReadLineKeyHandler | Where-Object {$_.Key -eq "Tab" }).Function
    __kubectl_debug "Mode: $Mode"

    $Values | ForEach-Object {

        # store temporary because switch will overwrite $_
        $comp = $_

        # PowerShell supports three different completion modes
        # - TabCompleteNext (default windows style - on each key press the next option is displayed)
        # - Complete (works like bash)
        # - MenuComplete (works like zsh)
        # You set the mode with Set-PSReadLineKeyHandler -Key Tab -Function <mode>

        # CompletionResult Arguments:
        # 1) CompletionText text to be used as the auto completion result
        # 2) ListItemText   text to be displayed in the suggestion list
        # 3) ResultType     type of completion result
        # 4) ToolTip        text for the tooltip with details about the object

        switch ($Mode) {

            # bash like
            "Complete" {

                if ($Values.Length -eq 1) {
                    __kubectl_debug "Only one completion left"

                    # insert space after value
                    [System.Management.Automation.CompletionResult]::new($($comp.Name | __kubectl_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")

                } else {
                    # Add the proper number of spaces to align the descriptions
                    while($comp.Name.Length -lt $Longest) {
                        $comp.Name = $comp.Name + " "
                    }

                    # Check for empty description and only add parentheses if needed
                    if ($($comp.Description) -eq " " ) {
                        $Description = ""
                    } else {
                        $Description = "  ($($comp.Description))"
                    }

                    [System.Management.Automation.CompletionResult]::new("$($comp.Name)$Description", "$($comp.Name)$Description", 'ParameterValue', "$($comp.Description)")
                }
             }

            # zsh like
            "MenuComplete" {
                # insert space after value
                # MenuComplete will automatically show the ToolTip of
                # the highlighted value at the bottom of the suggestions.
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __kubectl_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }

            # TabCompleteNext and in case we get something unknown
            Default {
                # Like MenuComplete but we don't want to add a space here because
                # the user need to press space anyway to get the completion.
                # Description will not be shown because that's not possible with TabCompleteNext
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __kubectl_escapeStringWithSpecialChars), "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }
        }

    }
}

#Register-ArgumentCompleter -CommandName 'kubectl' -ScriptBlock $__kubectlCompleterBlock
# Set Alias
Set-Alias -Name k -Value kubectl
Set-Alias -Name kubectl -Value kubecolor
# Register Autocomplete
Register-ArgumentCompleter -CommandName 'k','ks','kubectl','kubecolor','kubeswitch','talosctl','helm','switcher' -ScriptBlock $__kubectlCompleterBlock

Set-Alias -Name ks -Value kubeswitch
