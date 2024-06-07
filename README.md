<img src="https://raw.github.com/ClearMeasure/AliaSQL/master/images/AliaSQL.PNG" alt="AliaSQL" width="400">

What is AliaSQL?
--------------------------------
AliaSQL is a command line tool for database deployments. It is a drop in replacement for [Tarantino](https://github.com/HeadspringLabs/Tarantino) with some additional features.

How do I get started?
--------------------------------

Check out the [getting started guide](https://github.com/ClearMeasure/AliaSQL/wiki/Getting-started).

Check out the [wiki for some background information](https://github.com/ClearMeasure/AliaSQL/wiki/).

Read the blog posts [here](http://sharpcoders.org/post/Introducing-AliaSQL) and [here](http://jeffreypalermo.com/blog/aliasql-the-new-name-in-automated-database-change-management/).

There is also a C# runner as of version 1.4. Read about it here https://github.com/ClearMeasure/AliaSQL/wiki/C%23-runner

Where can I get it?
--------------------------------
First, [install NuGet](http://docs.nuget.org/docs/start-here/installing-nuget).

We recommend starting with the AliaSQL Kickstarter that creates Create, Update, Everytime, and TestData folders for your SQL scripts and  provides a Visual Studio runner. To get started, create an empty C# console app then install AliaSQL.Kickstarter from the package manager console:

    PM> Install-Package AliaSQL.Kickstarter

To get the the AliaSQL.exe tool by itself install AliaSQL from the package manager console:

    PM> Install-Package AliaSQL

To get the the c# runner install AliaSQL.Core from the package manager console:

    PM> Install-Package AliaSQL.Core


The latest compiled version can be found here: https://github.com/ClearMeasure/AliaSQL/raw/master/nuget/content/scripts/AliaSQL.exe

What else needs done?
---------------------
- More unit tests need written around Baseline, TestData, Update, and Everytime
- There are likely some additional things in SQL scripts that will fail when running in a transaction. More detail on this in the [getting started guide](https://github.com/ClearMeasure/AliaSQL/wiki/Getting-started).

Building
--------------------------------

There are several different ways to build the project, for various purposes.

To build the CLI, you must run these from the Console project directory (`source\AliaSQL.Console\`).

These examples build Windows x64 executables (`win-x64`), but the solution can also be built for linux using the `linux-x64` target, given to the `-r` (runtime) option.

## Fully Static Binary

To build a fully static binary that includes absolutely everything necessary:

```
dotnet publish -r win-x64 --property:Configuration=Release -p:PublishTrimmed=true -p:PublishSingleFile=true --self-contained true -f net6.0
```

This will build a single executable that will run anywhere. All dependencies are included in the final executable, which makes the file size very large (~45 MB).

## Partially Static Binary

To build static binary where non-system dependencies are in the final executable, but without system libs (.NET runtime) are not:

```
dotnet publish -r win-x64 -p:PublishSingleFile=true --self-contained false -f net6.0 --property:Configuration=Release
 ```

This should produce a single portable executable that will run on any system with the correct version of .NET installed. The executable is much smaller than a fully static binary.

## Trimmed Dynamically Linked Binary

To build dynamically linked release containing only necessary libraries (including system/runtime libs):

```
dotnet build --property:Configuration=Release -r win-x64 --self-contained false --property:PublishTrimmed=true
```

This will output the executable and all supporting DLLs into a final output directory, including the system libraries needed. This means a small executable, but the dependency DLLs must be on the path for it to run.
