# Microsoft Intune - ADMX to OMA-URI Generator

### Disclaimer

* There are likely certain ADMX policies out there that might not play well with this script. Most ADMX policies should be able to be processed by this script.

* This was created as a learning experience. There are solutions out there for this.

## Background

This script was created in order to help simplify the manual process of finding out all of the OMA-URI syntax and data values.

## Instructions

The script is pretty straight forward. Feed it a few parameters and it will generate a file containing the ADMX Ingestion URI and it can either report the settings via a grid or a csv.

## Parameters

|   Parameter | Type |Description | Required? |
|   :---      | :--- |:---        | :---      |
| ADMXFile    | FilePath |Path to the ADMX file | Yes |
| AppName | String |The Name of the app or component the ADMX is managing | Yes |
| CsvExport | Switch | If specified, exports a CSV to the working directory with the settings | No |

## Outputs

* **AppName-ADMX-Ingestion-OMA-URI.txt** - The ADMX Ingestion file will be placed in the script directory.
* **Grid** - A Grid window will open with the results if the script is ran without the `-CsvExport` parameter.
* **[Optional]  AppName-ADMX-Intune-Settings.csv** - If the `-CsvExport` Parameter is specified, the settings csv will be placed in the script directory instead of the default Grid option.

## Example

```powershell
PS C:\workingDirectory> .\Get-IntuneADMXURI.ps1 -ADMXFile 'C:\temp\admx template\GoogleChrome.admx' -AppName GoogleChrome
```
