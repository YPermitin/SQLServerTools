using System;
using System.IO;
using System.IO.Compression;
using System.Text;

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    public static class InternalFormatReader
    {
        public static string ParseToString(byte[] data)
        {
            string parsedValue;

            using (StreamReader stream = CreateReader(data))
            {
                parsedValue = ParseToString(stream);
            }

            return parsedValue;
        }

        private static string ParseToString(StreamReader stream)
        {
            return stream.ReadToEnd();
        }

        private static StreamReader CreateReader(byte[] data)
        {
            if (IsUTF8(data))
            {
                return CreateStreamReader(data);
            }
            return CreateDeflateReader(data);
        }

        private static StreamReader CreateStreamReader(byte[] data)
        {
            MemoryStream memory = new MemoryStream(data);
            return new StreamReader(memory, Encoding.UTF8);
        }

        private static StreamReader CreateDeflateReader(byte[] data)
        {
            MemoryStream memory = new MemoryStream(data);
            DeflateStream stream = new DeflateStream(memory, CompressionMode.Decompress);
            return new StreamReader(stream, Encoding.UTF8);
        }

        private static bool IsUTF8(byte[] fileData)
        {
            if (fileData == null)
                throw new ArgumentNullException(nameof(fileData));

            if (fileData.Length < 3)
                return false;

            return fileData[0] == 0xEF
                   && fileData[1] == 0xBB
                   && fileData[2] == 0xBF;
        }
    }
}
