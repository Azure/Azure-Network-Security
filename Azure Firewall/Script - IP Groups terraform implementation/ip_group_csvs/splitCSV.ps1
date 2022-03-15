#simple script to split an input CSV into multiple row limited files
#Parameters: Input Filename, Rowmax
Param (
    [Parameter(Mandatory=$true)][string]$inputFile,
    [string]$maxRows=5000,
    [string]$outFilePrefix="ipg_part_",
    [string]$headerRow=$true,
    [string]$headerValue="cidr"
)

$inputFileContent = Get-Content "$(Get-Location)\$inputFile"

#Define and initialize variables
$totalLineCounter = 0
$fileCounter = 0
$rowCounter = 0
$count = 0

#move the pointers if a header row exists
if ($headerRow){
    $rowCounter = 1
    $count = $rowCounter
}

while ($totalLineCounter -le $inputFileContent.Length) {   
    if ($rowCounter -eq $maxRows -Or $totalLineCounter -eq $inputFileContent.Length) {
        $fileCounter++
        $newFilename = ($outFilePrefix + $fileCounter + ".csv")
        #overwrite with the header column to avoid appending to an existing file
        $headerValue | Out-File -FilePath "$(Get-Location)\$newFilename" 
        $inputFileContent[$count..($totalLineCounter-1)].Trim() | Where-Object {$_.Name -ne ''} | Add-Content -Path "$(Get-Location)\$newFilename" 

        #update the start counter
        $count = $totalLineCounter
        $rowCounter = 0 
        Write-Host $newFilename
    }
    $rowCounter++
    $totalLineCounter++
}