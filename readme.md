# Microsoft Intune - ADMX to OMA-URI Generator

\*Disclaimer - This tool is very early on in development. There are likely certain ADMX policies out there that might not play well with this script. Most ADMX policies should be able to be processed by this script.

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

## Example

```powershell
PS C:\workingDirectory> .\Get-IntuneADMXURI.ps1 -ADMXFile 'C:\temp\admx template\GoogleChrome.admx' -AppName GoogleChrome
```
