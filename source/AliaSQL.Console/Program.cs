using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using AliaSQL.Core;
using AliaSQL.Core.Model;
using AliaSQL.Core.Services.Impl;
using CommandLine;

namespace AliaSQL.Console
{
    public class Program
    {

        public static void Main(string[] args)
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);

            System.Console.Title = "AliaSQL Database Deployment Tool";
            var deployer = new ConsoleAliaSQL();

            var parser = new Parser(with =>
            {
                //ignore case for enum values
                with.CaseInsensitiveEnumValues = true;
            });
            Environment.ExitCode = 3; // unknown error
            var o = parser.ParseArguments<Options>(args)
            .WithParsed<Options>(o =>
            {
                var settings = new ConnectionSettings(o.server, o.database, o.integratedAuth, o.username, o.password, o.trustServerCertificate);
                System.Console.WriteLine("Using connection string:" + settings);
                var success = deployer.UpdateDatabase(settings, o.scriptDirectory, o.action);
                Environment.ExitCode = success ? 1 : 2;
            })
            .WithNotParsed(e =>
            {
                InvalidArguments(e);
            });
        }

        private static void InvalidArguments(IEnumerable<Error> errs)
        {
            System.Console.WriteLine("Invalid Arguments");
            System.Console.WriteLine(" ");
            System.Console.WriteLine( Path.GetFileName(typeof(Program).Assembly.Location) + @" Action(Create|Update|Rebuild|TestData|Baseline|Drop) .\SqlExpress DatabaseName  .\DatabaseScripts\ ");
            System.Console.WriteLine(Environment.NewLine + "-- or --"+ Environment.NewLine);
            System.Console.WriteLine( Path.GetFileName(typeof(Program).Assembly.Location) + @" Action(Create|Update|Rebuild|TestData|Baseline|Drop) .\SqlExpress DatabaseName  .\DatabaseScripts\ Username Password");
            System.Console.WriteLine(Environment.NewLine + "---------------------------------------------" + Environment.NewLine);           
            System.Console.WriteLine("Create - Creates database and runs scripts in 'Create' and 'Update' folders.");
            System.Console.WriteLine(" ");
            System.Console.WriteLine("Update - Runs scripts in 'Update' folder. If database does not exist it will create it and run scripts in the 'Create' folder first.");
            System.Console.WriteLine(" ");
            System.Console.WriteLine("Rebuild - Drops then recreates database then runs scripts in 'Create' and 'Update' folders");
            System.Console.WriteLine(" "); 
            System.Console.WriteLine("TestData - Runs scripts in 'TestData' folder. Database must already exist. Seed scripts are logged separate from Create and Update scripts.");
            System.Console.WriteLine(" "); 
            System.Console.WriteLine("Baseline - Creates usd_AppliedDatabaseScripts table and logs all current scripts in 'Create' and 'Update' folders as applied without actually running them.");
            System.Console.WriteLine(" ");
            System.Console.WriteLine("Drop - Drops the database");

            foreach (var error in errs)
            {
                System.Console.WriteLine($"error.Tag: {error.Tag}, error.StopsProcessing: {error.StopsProcessing}");
            }
            if (Debugger.IsAttached)
                System.Console.ReadLine();
        }
    }
    
    public class Options {
        [Value(0, Default = RequestedDatabaseAction.Default, Required = true)] 
        public RequestedDatabaseAction action { get; set; }
            
        [Value(1, Required = true, MetaName = "DatabaseServer", HelpText = "Database Server")] 
        public string server { get; set; }
            
        [Value(2, Required = true, MetaName = "DatabaseName", HelpText = "Database Name")]
        public string database { get; set; }
            
        [Value(3, Required = true, MetaName = "Scripts path", HelpText = "Scripts path, e.g. ./sqlScripts/")]
        public string scriptDirectory { get; set; }
        
        [Option(shortName: 'u', longName:"user", Default = null)]
        public string username { get; set; }
            
        [Option(shortName: 'p', longName:"pass", Default = null)]
        public string password { get; set; }

        public bool integratedAuth
        {
            get
            {
                return String.IsNullOrEmpty(username);
            }
        }

        [Option(shortName: 't', longName:"trustServerCertificate", Default = false) ]
        public bool trustServerCertificate { get; set; }
    }
}