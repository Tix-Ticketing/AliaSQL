using System;
using System.IO;
using System.Text;
using Ude;
using UtfUnknown;

namespace AliaSQL.Core
{
    public class FileSystem : IFileSystem
    {
        private readonly IFileStreamFactory _streamFactory;

        public FileSystem(IFileStreamFactory streamFactory)
        {
            _streamFactory = streamFactory;
        }

        public FileSystem():this(new FileStreamFactory())
        {
        
        }

        public void SaveFile(string filename, byte[] fileContent)
        {
            if (fileContent != null)
            {
                var fileStream = _streamFactory.ConstructWriteFileStream(filename);

                using (var writer = new BinaryWriter(fileStream))
                {
                    writer.Write(fileContent);
                }
            }
        }

        public bool FileExists(string relativePath)
        {
            var retval = File.Exists(relativePath);
            return retval;
        }

        public Stream ReadIntoFileStream(string path)
        {
            try
            {
                var stream = _streamFactory.ConstructReadFileStream(path);
                return stream;
            }
            catch (IOException ex)
            {
                if (ex.Message.IndexOf("it is being used by another process") >= 0)
                {
                    throw new ApplicationException("The file you chose cannot be read because it is open in another application.  Please close the file in the other application and try again.");
                }

                throw;
            }
        }

        public string[] GetAllFilesWithExtensionWithinFolder(string folder, string fileExtension)
        {
            var fileNames = new string[0];

            if (Directory.Exists(folder))
            {
                var searchPattern = string.Format("*.{0}", fileExtension);
                fileNames = Directory.GetFiles(folder, searchPattern, SearchOption.AllDirectories);
            }

            return fileNames;
        }

        public string ReadTextFile(string filename)
        {
            var stream = _streamFactory.ConstructReadFileStream(filename);

            Encoding encoding = GetEncoding(filename);
            System.Console.WriteLine("Encoding is " + encoding);
            using (var reader = new StreamReader(stream, encoding))
            {
                return reader.ReadToEnd();
            }
        }

        /// <summary>
        /// Determine's a text file's encoding by using a universal encoding detector.
        /// </summary>
        /// <param name="filename">The text file to analyze.</param>
        /// <returns>The detected encoding.</returns>
        private static Encoding GetEncoding(string filename)
        {
            using (var file = File.OpenRead(filename))
            {

                var detector = new Ude.CharsetDetector();
                detector.Feed(file);
                detector.DataEnd();

                if (detector.Charset != null)
                {
                    return Encoding.GetEncoding(detector.Charset);
                }
                else
                {
                    return Encoding.ASCII;
                }
            }
        }

        public StreamReader ReadFileIntoStreamReader(string filename)
        {
            var stream = _streamFactory.ConstructReadFileStream(filename);
            var reader = new StreamReader(stream);
            return reader;
        }
    }
}