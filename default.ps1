properties {
	$projectName = "AliaSQL"
    $version = "2.0.1"

    $version = $version + "." + (get-date -format "MMdd")  
	$projectConfig = "Release"
	$base_dir = resolve-path .
	$source_dir = "$base_dir\source"
    $unitTestAssembly = "$projectName.UnitTests.dll"
    $integrationTestAssembly = "$projectName.IntegrationTests.dll"
    $nunitPath = "$source_dir\packages\NUnit.ConsoleRunner.3.12.0\tools\nunit3-console.exe"
    $AliaSQLPath = "$base_dir\lib\AliaSQL\AliaSQL.exe"
	$build_dir = "$base_dir\build"
	$test_dir = "$build_dir\test"
	$testCopyIgnorePath = "_ReSharper"
	$package_dir = "$build_dir\package"	
	$package_file = "$build_dir\latest\" + $projectName +"_Package.zip"
	$databaseServer = ".\sqlexpress"
	$databaseScripts = "$source_dir\Database.Demo"
    $integrationScripts = "$source_dir\AliaSQL.IntegrationTests\scripts"
	$databaseName = "Demo"
    $SqlPackagePath = "C:\Program Files (x86)\Microsoft SQL Server\110\DAC\bin\SqlPackage.exe"
        $SqlPackagePath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\150\SqlPackage.exe"
    if (!(Test-Path  ("$SqlPackagePath"))){
        write-host "Switch to SQL Server 2017 for packaging"
        $SqlPackagePath = "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe"  
    }
    if (!(Test-Path  ("$SqlPackagePath"))){
        write-host "Switch to SQL Server 2016 for packaging"
        $SqlPackagePath = "C:\Program Files (x86)\Microsoft SQL Server\130\DAC\bin\SqlPackage.exe"  
    }

}

task default -depends Init, Compile, Test, IntegrationTest 
task ci -depends Init, Compile, Test, IntegrationTest, Package, NugetPack

task Init {
    delete_file $package_file
    delete_directory $build_dir
    create_directory $test_dir
	create_directory $build_dir
}

task Compile -depends Init {
    exec { & $source_dir\.nuget\nuget.exe restore  $source_dir\$projectName.sln }  
    exec{dotnet clean -c $projectConfig /p:VisualStudioVersion=16.0 $source_dir\$projectName.sln}
    exec{dotnet build -c $projectConfig /p:VisualStudioVersion=16.0 $source_dir\$projectName.sln /p:AssemblyVersion=$version}

    ILMergeAndCopy
}

task Test {
    if (Test-Path  ("$nunitPath")){
        copy_all_assemblies_for_test $test_dir
        
        if (Test-Path  ("$test_dir\$unitTestAssembly")){
            write-host "Testing $unitTestAssembly"
	        exec {
		        & $nunitPath $test_dir\$unitTestAssembly --work:$build_dir    
	        }
        }
        else
        {
            write-host "Cannot run unit tests as $nunitPath\$unitTestAssembly is MISSING"
        }
    }
    else{
      write-host "Cannot run tests as $nunitPath is MISSING"
    }
}

task IntegrationTest -depends  Init, Compile, Test {
    if (Test-Path  ("$nunitPath")){
        copy_all_assemblies_for_test "$test_dir"
         Copy_files "$integrationScripts" "$test_dir/scripts"
        if (Test-Path  ("$test_dir\$integrationTestAssembly")){
            write-host "Testing $integrationTestAssembly"
            cd .\build
            cd .\test
            exec { & $nunitPath $test_dir\$integrationTestAssembly  --work:$build_dir}
        }
        else
        {
            write-host "Cannot run integration tests as $test_dir\$integrationTestAssembly is MISSING"
        }
    }
    else{
      write-host "Cannot run tests as $nunitPath is MISSING"
    }
}


task UpdateAssemblyInfo {
    Update-AssemblyInfoFiles $version
}

task RebuildDatabase {
    exec { & $AliaSQLPath Rebuild $databaseServer "$databaseName" "$databaseScripts\Scripts"}
}

task UpdateDatabase {
        exec { & $AliaSQLPath Update $databaseServer "$databaseName" "$databaseScripts\Scripts"}
}

task TestDataDatabase { 
    exec { &  $AliaSQLPath TestData $databaseServer " $databaseName" "$databaseScripts\Scripts"}
}

task Package -depends Compile {	
    write-host "Copy in database scripts"
    copy_files "$databaseScripts\scripts" "$package_dir\database\"
    write-host "Copy AliaSQL tool so scripts can be ran"
    copy-item "$AliaSQLPath"  "$package_dir\database\AliaSQL.exe"
    write-host "Create batch files to run db updates"
    create-dbdeployscript "Update" "$package_dir\database\_Update-Database.bat"
    create-dbdeployscript "Rebuild" "$package_dir\database\_Rebuild-Database.bat"
    create-dbdeployscript "Baseline"  "$package_dir\database\_Baseline-Database.bat"
    create-dbdeployscript "Seed" "$package_dir\database\_Seed-Database.bat"
    write-host "Zip it up"
	zip_directory $package_dir $package_file 
}
 

 task NugetPack -depends Package {
 exec {
    & $source_dir\.nuget\nuget.exe pack -Version $version -outputdirectory $build_dir $base_dir\nuget\AliaSQL.nuspec
    }
 exec {
    & $source_dir\.nuget\nuget.exe pack -Version $version -outputdirectory $build_dir $base_dir\nuget\AliaSQL.Kickstarter.nuspec
    }
     exec {
    & $source_dir\.nuget\nuget.exe pack -Version $version -outputdirectory $build_dir $base_dir\nuget\AliaSQL.Core.nuspec
    }
}

  function global:ILMergeAndCopy {
    write-host "ILMergeAndCopy"
    write-host "Copy newly compiled version of AliaSQL to package folder"
    copy_files "$base_dir\source\AliaSQL.Console\Bin\Release" "$package_dir\AliaSQL" 
    copy-item "$base_dir\source\AliaSQL.Core\bin\Release\net461\AliaSQL.Core.xml" "$package_dir\AliaSQL\net461\AliaSQL.Core.xml" 
    exec {
        & $base_dir\lib\ilmerge.exe /ndebug /target:exe /targetplatform:v4,"C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.6.1"  /out:$package_dir\AliaSQL\AliaSQL.exe $package_dir\AliaSQL\net461\AliaSQL.console.exe $package_dir\AliaSQL\net461\AliaSQL.core.dll  
        }
    write-host "Copy newly compiled version of AliaSQL to Nuget package folder"
    copy-item $package_dir\AliaSQL\AliaSQL.exe $base_dir\nuget\content\scripts\AliaSQL.exe -Force
	write-host "Copy newly compiled version of AliaSQL to Demo project"
	copy-item $package_dir\AliaSQL\AliaSQL.exe $source_dir\Database.Demo\scripts\AliaSQL.exe -Force
    write-host "Copy newly compiled version of AliaSQL to lib"
	copy-item $package_dir\AliaSQL\AliaSQL.exe $base_dir\lib\AliaSQL\AliaSQL.exe -Force
}

task GenerateDatabaseDiff {
    create-dbdiffscript $databaseName $databaseScripts
}

function create-dbdiffscript([string]$database_name, [string]$database_scripts)
{
    $databaseName_Original = "$datebase_name" + "_Original"
    $databaseScriptsUpdate = "$database_scripts\Scripts\Update"
    $newScriptName = ((Get-ChildItem $databaseScriptsUpdate -filter "*.sql" | ForEach-Object {[int]$_.Name.Substring(0, 4)} | Sort-Object)[-1] + 1).ToString("0000-") + "$database_name" + ".sql.temp"

    write-host "Building original database..."
    copy_files "$databaseScripts\Deploy-Once" "$package_dir\temp\DBCreate\update"
    exec { & $AliaSQLPath Rebuild $databaseServer "$databaseName_Original" "$database_scripts\Scripts"}
    
    write-host "`n`nGenerating the diff script"
    #generate the needed .dacpac (we'll delete it later)
    exec { & $SqlPackagePath /a:Extract /ssn:.\SQLEXPRESS /sdn:"$database_name" /tf:$databaseScripts\$database_name.dacpac }
    #generate the diff script
    exec { & $SqlPackagePath /a:Script /op:$databaseScriptsUpdate\$newScriptName /sf:$databaseScripts\$database_name.dacpac /tsn:.\SQLEXPRESS /tdn:"$databaseName_Original"}
    
    write-host "`n`nCleaning up generated script..."
    $scriptLines = Get-Content $databaseScriptsUpdate\$newScriptName
    Clear-Content $databaseScriptsUpdate\$newScriptName

    $passedLastSqlCmd = $false
    $skipBlock = $false
    $blocksToSkip = "usd_AppliedDatabaseScript","usd_AppliedDatabaseTestDataScript", "IX_usd_DateApplied"
    $noDiff = $true
    $noDiffLines = "", "GO", "PRINT N'Update complete.';" #these are the only lines left when there are no DB diffs
    foreach($line in $scriptLines)
    {   
        #don't add anything until we get past the line USE [`$(DatabaseName)]; -- all the previous stuff should be sqlcmd/unncessary junk 
        if ($line -eq "USE [`$(DatabaseName)];")
        {
            $passedLastSqlCmd = $true
        }
        #skip any blocks which contain any of the text in the skippable array
        elseif ($blocksToSkip | Where-Object { $line.Contains($_) })
        {
             $skipBlock = $true
        }        
        elseif ($passedLastSqlCmd -and -not $skipBlock)
        {
            $newLine = "$line"
            Add-Content $databaseScriptsUpdate\$newScriptName "$newLine"

            if ($noDiff)
            {
                $noDiff = $noDiffLines.Contains($newLine)
            }
        }
        elseif ($line -eq "GO")
        {
            $skipBlock = $false
        }
    }    

    write-host "Cleaning up temporary files and databases..."
    exec { & del $databaseScripts\$database_name.dacpac }
    exec { & sqlcmd -S .\SQLEXPRESS -Q "DROP DATABASE $databaseName_Original"  }

    if ($noDiff)
    {
        Remove-Item $databaseScriptsUpdate\$newScriptName
         write-host "No schema changes found for $database_name" -foregroundcolor "green"
    }
    else 
    {
        write-host "Please validate the new script $databaseScriptsUpdate\$newScriptName is correct, then rename to .sql and add to the database project" -foregroundcolor "yellow"
    }
}

function global:zip_directory($directory,$file) {
    write-host "Zipping folder: " $test_assembly
    delete_file $file
    cd $directory
    & "$base_dir\lib\7zip\7za.exe" a -mx=9 -r $file
    cd $base_dir
}

function global:copy_files($source,$destination,$exclude=@()){    
    create_directory $destination
    Get-ChildItem $source -Recurse -Exclude $exclude -ErrorAction SilentlyContinue | Copy-Item -ErrorAction SilentlyContinue -Destination {Join-Path $destination $_.FullName.Substring($source.length)} 
}

function global:Copy_and_flatten ($source,$filter,$dest) {
  ls $source -filter $filter  -r | Where-Object{!$_.FullName.Contains("$testCopyIgnorePath") -and !$_.FullName.Contains("packages") -and !$_.FullName.Contains("build") }| cp -dest $dest -force
}

function global:copy_all_assemblies_for_test($destination){
  create_directory $destination
  Copy_and_flatten $source_dir *.exe $destination
  Copy_and_flatten $source_dir *.dll $destination
  Copy_and_flatten $source_dir *.config $destination
  Copy_and_flatten $source_dir *.xml $destination
  Copy_and_flatten $source_dir *.pdb $destination
}

function global:delete_file($file) {
    if($file) { remove-item $file -force -ErrorAction SilentlyContinue | out-null } 
}

function global:delete_directory($directory_name)
{
  rd $directory_name -recurse -force  -ErrorAction SilentlyContinue | out-null
}

function global:delete_files_in_dir($dir)
{
	get-childitem $dir -recurse | foreach ($_) {remove-item $_.fullname}
}

function global:create_directory($directory_name)
{
  mkdir $directory_name  -ErrorAction SilentlyContinue  | out-null
}

function create-dbdeployscript($verb, $filename)
{ 
"@echo off
set /p serverName=""DB Server: "" %=%
AliaSQL.exe $verb %serverName% $databaseName . 
pause" | out-file $filename -encoding "ASCII"       
}


