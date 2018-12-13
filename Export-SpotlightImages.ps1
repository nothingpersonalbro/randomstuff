<#
.SYNOPSIS
    Export Windows Spotlight lockscreen images to a new directory.
.DESCRIPTION
    Windows Spotlight lockscreen images automatically get downloaded and stored temporarily.
    This will allow you to export and save those images to a permanent location.
    Checks the destination if any duplicate files exist (using SHA256 hash).
.EXAMPLE
    Export-SpotlightImages -DestinationFolder C:\Temp\Wallpapers
    Copies all landscape images by default.
.EXAMPLE
    Export-SpotlightImages -DestinationFolder C:\Wallpapers -Portrait
    Copies all portrait images.
.NOTES
    Uses .NET to determine image width.
    Tested on Win10 PS 5.1
#>
function Export-SpotlightImages {
    [CmdletBinding(
        DefaultParameterSetName = 'Parameter Landscape',
        SupportsShouldProcess,
        ConfirmImpact = 'Medium'
    )]
    param (
        # Destination where the new files will be created.
        [Parameter(
            Mandatory,
            Position = 0,
            HelpMessage = 'Specify the path of your target destination.'
        )]
        [Parameter(ParameterSetName = 'Parameter Landscape')]
        [Parameter(ParameterSetName = 'Parameter Portrait')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationFolder,

        # Selects landscape images only.
        [Parameter(ParameterSetName = 'Parameter Landscape')]
        [switch]
        $Landscape,

        # Selects portrait images only.
        [Parameter(ParameterSetName = 'Parameter Portrait')]
        [switch]
        $Portrait
    )

    process {
        # Create the destination folder if it doesn't exist.
        if (-not (Test-Path $DestinationFolder)) {
            try {
                $DestCreate = New-Item -Path $DestinationFolder -ItemType Directory
                Write-Verbose "Created new directory: $($DestCreate.FullName)"
            }
            catch {
                throw
            }
        }

        # Main image copy process.
        if ($pscmdlet.ShouldProcess("Destination: $DestinationFolder", 'Copy Images')) {
            # Prepare the environment.
            [void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
            $NewImageList = [System.Collections.Generic.List[string]]::new()
            [int]$i = 1

            # Build image source path.
            $Source = Join-Path -Path $env:USERPROFILE -ChildPath (
                "AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_*\LocalState\Assets\*"
            )

            # Populate temp image location.
            $TempImageList = Copy-Item -Path $Source -Destination $env:TEMP -PassThru

            # Get file hashes of the destination for duplicate detection.
            $HashList = [System.Collections.Generic.HashSet[string]]@(
                (Get-ChildItem -Path $DestinationFolder | Get-FileHash).Hash
            )

            # Main image operation.
            foreach ($Image in $TempImageList) {
                try {
                    $i++
                    # Get file hash and compare against the destination contents.
                    $ImageHash = (Get-FileHash -Path $Image).Hash
                    if ($HashList.Contains($ImageHash)) {
                        Write-Verbose "Skipping $($Image.Name), file already exists."
                        continue
                    }
                    # Rename the new image.
                    $NewName = 'Wallpaper{0:yyyyMMddhhmmss}{1:D3}.jpg' -f (Get-Date), $i
                    $Renamed = Rename-Item -Path $Image -NewName $NewName -PassThru

                    # Determine image width.
                    $LoadImage = [System.Drawing.Image]::FromFile($Renamed.FullName)
                    switch ($true) {
                        $Landscape {[int]$Width = 1920; $Orientation = 'Landscape'}
                        $Portrait  {[int]$Width = 1080; $Orientation = 'Portrait' }
                        Default    {[int]$Width = 1920; $Orientation = 'Landscape'}
                    }

                    # Remove images that don't fit the orientation requirements.
                    if ($LoadImage.Width -ne $Width) {
                        $LoadImage.Dispose()
                        Remove-Item -Path $Renamed
                        Write-Verbose "Skipping $($Renamed.Name), not in '$Orientation' mode."
                    }
                    else {
                        $LoadImage.Dispose()
                        $NewImageList.Add($Renamed.FullName)
                    }
                }
                catch [System.Management.Automation.MethodInvocationException] {
                    Write-Verbose "Skipping $($Renamed.Name), not a valid image file."
                    Remove-Item -Path $Renamed
                }
                catch {
                    Write-Verbose "Cannot copy $Image"
                }
            }
        }
    }

    end {
        # Copy images to the new destination, then cleanup.
        if ($NewImageList) {
            Copy-Item -Path $NewImageList -Destination $DestinationFolder
            $NewImageList | Remove-Item -ErrorAction SilentlyContinue
        }

        # Clean up temp images.
        if ($TempImageList) {$TempImageList | Remove-Item -ErrorAction SilentlyContinue}

        Write-Output "$($NewImageList.Count) images have been created in '$DestinationFolder'."
    }
}
