namespace AliaSQL.Core.Model
{
	public class ConnectionSettings
	{
		private string _database;
		private bool _integratedAuthentication;
		private string _password;
		private string _server;
		private string _username;
		private bool _trustServerCertificate;
		
		public ConnectionSettings(string server, string database, bool integratedAuthentication, string username,
		                          string password, bool trustServerCertificate = false)
		{
			_server = server;
			_database = database;
			_integratedAuthentication = integratedAuthentication;
			_username = username;
			_password = password;
			_trustServerCertificate = trustServerCertificate;
		}

		public string Database
		{
			get { return _database; }
		}

		public bool IntegratedAuthentication
		{
			get { return _integratedAuthentication; }
		}

		public string Password
		{
			get { return _password; }
		}

		public string Server
		{
			get { return _server; }
		}

		public string Username
		{
			get { return _username; }
		}
		
		public bool TrustServerCertificate
		{
			get { return _trustServerCertificate; }
		}

		public override bool Equals(object obj)
		{
			ConnectionSettings settings = (ConnectionSettings)obj;

			bool serverMatches = Server == settings.Server;
			bool databaseMatches = Database == settings.Database;
			bool integratedMatches = IntegratedAuthentication == settings.IntegratedAuthentication;
			bool usernameMatches = Username == settings.Username;
			bool passwordMatches = Password == settings.Password;
			bool trustServerCertificateMatches = TrustServerCertificate == settings.TrustServerCertificate;

			return (serverMatches && databaseMatches && integratedMatches && usernameMatches && passwordMatches && trustServerCertificateMatches);
		}

		public override int GetHashCode()
		{
			string combinedKey = _server + _database + _username + _password + _integratedAuthentication + _trustServerCertificate;
			int hashCode = combinedKey.GetHashCode();
			return hashCode;
		}
	}
}