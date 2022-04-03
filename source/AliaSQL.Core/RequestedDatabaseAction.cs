using System;

namespace AliaSQL.Core
{
	[Flags]
	public enum RequestedDatabaseAction
	{
		Default, Create, Update, Drop, Rebuild, TestData, Baseline
	}	
}