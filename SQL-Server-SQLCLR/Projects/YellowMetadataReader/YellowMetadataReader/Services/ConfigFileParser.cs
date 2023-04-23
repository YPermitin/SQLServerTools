using System.IO;
using YPermitin.SQLCLR.YellowMetadataReader.Models;

namespace YPermitin.SQLCLR.YellowMetadataReader.Services
{
    public sealed class ConfigFileParser
    {
        public ConfigObject Parse(StreamReader stream)
        {
            return ParseFile(stream, null);
        }
        private ConfigObject ParseFile(StreamReader stream, ConfigObject parent)
        {
            char c;
            string value = null;
            ConfigObject cfo = null;
            while (!stream.EndOfStream)
            {
                do
                {
                    c = (char)stream.Read();
                }
                while (c == '\r' || c == '\n');

                if (c == '{') // start of object
                {
                    cfo = new ConfigObject();
                    ParseFile(stream, cfo);
                    if (parent != null) // this is child object
                    {
                        parent.Values.Add(cfo);
                    }
                }
                else if (c == '}') // end of object
                {
                    if (value != null)
                    {
                        parent?.Values.Add(value);
                    }
                    return cfo; 
                }
                else if (c == '"') // start of string value
                {
                    value = string.Empty;
                    while (!stream.EndOfStream)
                    {
                        c = (char)stream.Read();
                        if (c == '"') // might be end of string
                        {
                            c = (char)stream.Read();
                            if (c == '"') // double quotes - this is not the end
                            {
                                value += c;
                            }
                            else // this is the end
                            {
                                parent?.Values.Add(value);
                                value = null;
                                if (c == '}') // end of object
                                {
                                    return cfo;
                                }
                                break;
                            }
                        }
                        else
                        {
                            value += c;
                        }
                    }
                }
                else if (c == ',') // end of value
                {
                    if (value != null)
                    {
                        parent?.Values.Add(value);
                        value = null;
                    }
                }
                else // number or uuid value
                {
                    if (value == null)
                    {
                        value = c.ToString();
                    }
                    else
                    {
                        value += c;
                    }
                }
            }
            return cfo;
        }
    }
}