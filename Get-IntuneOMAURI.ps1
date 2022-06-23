<#
.Synopsis
   Reads ADMX files and outputs all of the possible OMA-URI Settings you can set with it.
.DESCRIPTION
   Easily convert ADMX files into OMA-URI for Microsoft Intune. Feed this script a admx file and it will output all of the OMI-URI and the options available for each setting.
.EXAMPLE
   .\Get-IntuneOMAURI.ps1 -ADMXFile 'C:\temp\admx template\GoogleChrome.admx -AppName GoogleChrome

   This example pulls in the GoogleChrome.admx file and will open a grid view of all the settings afterwards.
   The AppName helps create the ADMX Ingestion URI.
#>

Param(
    [Parameter (Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (-not ($_ | Test-Path)) {
            throw "File not Found. Check the file path you speicfied"
        }
        return $true
    })]
    [System.IO.FileInfo]$ADMXFile,

    [Parameter (Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,

    [Parameter (Mandatory=$false)]
    [ValidateNotNullorEmpty()]
    [switch]$CsvExport = $false
)

# Results storage
$results = @()

# Lets build out the OMA-URI for Ingesting the ADMX file
$admxIngestionURI = "./Device/Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/{0}/Policy/{1}" -f $AppName,"$($AppName)Admx"
$settingURI = "./Device/Vendor/MSFT/Policy/Config/{0}~Policy<category>/" -f $AppName

# Prep the ADMX file for parsing
[xml]$admxData = Get-Content $ADMXFile
$categories = $admxData.policyDefinitions.categories.category

# Need to build out Categories to be able to build the setting OMA-URI properly

foreach ($policy in $admxData.policyDefinitions.policies.policy) {

   # building OMA-URI for this policy
   [string]$policyCategoryURI = "~$($policy.ParentCategory.ref)"
   while ($true) {
      
      if (($categories | Where-Object {$_.Name -eq $policyCategoryURI.Split('~')[1]}).PSObject.Properties.name -match "parentCategory" ) {
         # The current category has a parent
         $policyCategoryURI = "~$(($categories | Where-Object {$_.Name -eq $policyCategoryURI.Split('~')[1]}).parentCategory.ref)$policyCategoryURI"
      }
      else {
         # No more parents exist break the loop
         break
      }
   } # end Build OMA-URI Setting

   if ($null -ne $policy.enabledList) {

      # Take a look at the Enabled/Disable policies
      $results += [PSCustomObject]@{
         Name = $policy.name
         "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
         Setting = "<enabled/> OR <disabled/>"
      }
      continue
   }

   # If the setting only contains elements
   elseif ($null -ne $policy.elements) {

      foreach ($element in $policy.elements) {
         # Check the Type of Element
         switch ($element.PSobject.Properties.name) {
            'enum' {
               # Basically a list of options

               [string]$enumSetting = ""

               switch (($element.enum.item.value | Get-Member | Where-Object {$_.MemberType -eq 'Property'}).Name) {
                  'string' {
                     foreach ($item in $element.enum.item.value.string) {

                        $enumSetting += "<enabled/> <data id=$($element.enum.id) -value `"$($item)`"/>`n"
      
                     }
                  }

                  'decimal' {
                     foreach ($item in $element.enum.item.value.decimal.value) {

                        $enumSetting += "<enabled/> <data id=$($element.enum.id) -value `"$($item)`"/>`n"
      
                     }
                  }
               }               

               $results += [PSCustomObject]@{
                  Name = $policy.name
                  "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
                  Setting = $enumSetting
               }
            } # end enum

            'decimal' {
               # A simple numeric option that limits

               # Check if there are limits on the decimal
               if ($null -eq $element.decimal.minValue) {
                  $results += [PSCustomObject]@{
                     Name = $policy.name
                     "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
                     Setting = "<enabled/> <data id=$($element.decimal.id) value=`"<!-- Max Value of: $($element.decimal.maxValue) -->`"/>`n"
                  }
               }
               elseif ($null -eq $element.decimal.maxValue) {
                  $results += [PSCustomObject]@{
                     Name = $policy.name
                     "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
                     Setting = "<enabled/> <data id=$($element.decimal.id) value=`"<!-- Min Value of: $($element.decimal.minValue) -->`"/>`n"
                  }
               }
               else {
                  $results += [PSCustomObject]@{
                     Name = $policy.name
                     "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
                     Setting = "<enabled/> <data id=$($element.decimal.id) value=`"<!-- Value Range: $($element.decimal.minValue)-$($element.decimal.maxValue) -->`"/>`n"
                  }
               }
            } # end decimal

            'text' {
               # Need to check if the Max Length is set

               if ($null -eq $element.text.maxLength) {
                  $results += [PSCustomObject]@{
                     Name = $policy.name
                     "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
                     Setting = "<enabled/> <data id=$($element.decimal.id) value=`"<!-- [String] -->`"/>`n"
                  }
               }
               else {
                  $results += [PSCustomObject]@{
                     Name = $policy.name
                     "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
                     Setting = "<enabled/> <data id=$($element.decimal.id) value=`"<!-- [String] Max Length: $($element.text.maxLength) -->`"/>`n"
                  }
               }
            } # end text
         } # end element switch
      } # end foreach element
   } # end if element

   # Simple Enable only setting
   else {
      
      # elements, enableList, and disableList properties are not present, this is simply an enable rule
      $results += [PSCustomObject]@{
         Name = $policy.name
         "OMA-URI" = "$($settingURI.Replace('<category>',$policyCategoryURI))$($policy.name)"
         Setting = "<enabled/>"
      }
      continue
   } # End simple Enable Setting
} # end foreach Policy

# Output ADMX Ingestion OMA-URI
$admxIngestionURI | Out-File -FilePath "$PSScriptRoot\$AppName-ADMX-Ingestion-OMA-URI.txt" -Force

if ($CsvExport) {
   $results | Export-Csv -Path "$PSScriptRoot\$AppName-ADMX-Intune-Settings.csv" -NoTypeInformation -Force
} else {
   $results | Out-GridView
}
