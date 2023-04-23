using System;
using System.Collections.Generic;
using YPermitin.SQLCLR.YellowMetadataReader.Helpers;
using YPermitin.SQLCLR.YellowMetadataReader.Models;
using YPermitin.SQLCLR.YellowMetadataReader.Services;

namespace YPermitin.SQLCLR.YellowMetadataReader.Enrichers
{
    public sealed class DbNamesEnricher : IContentEnricher
    {
        // ReSharper disable once InconsistentNaming
        private const string DBNAMES_FILE_NAME = "DBNames"; // Params
        private Configurator Configurator { get; }
        public DbNamesEnricher(Configurator configurator)
        {
            Configurator = configurator;
        }
        public void Enrich(MetadataObject metadataObject)
        {
            if (!(metadataObject is InfoBase infoBase)) throw new ArgumentOutOfRangeException();

            ConfigObject configObject = Configurator.FileReader.ReadConfigObject(DBNAMES_FILE_NAME);

            int entryCount = configObject.GetInt32(new[] { 1, 0 });

            for (int i = 1; i <= entryCount; i++)
            {
                Guid uuid = configObject.GetUuid(new[] { 1, i, 0 });

                string token = configObject.GetString(new[] { 1, i, 1 });

                int code;
                if (uuid == Guid.Empty)
                {
                    code = 0;
                }
                else
                {
                    code = configObject.GetInt32(new[] { 1, i, 2 });
                }

                ProcessEntry(infoBase, uuid, token, code);
            }
        }
        private void ProcessEntry(InfoBase infoBase, Guid uuid, string token, int code)
        { 
            string fullKey = GeneralHelper.GenerateConfigFullObjectKey(uuid, token, code);
            
            if (token.StartsWith("ByField") 
                || token.StartsWith("ByOwnerField") 
                || token.StartsWith("ByParentField") 
                || token.StartsWith("ByDims")
                || token.StartsWith("ByProperty")
                || token.StartsWith("ByResource")
                || token.StartsWith("EDBT")
                || token.StartsWith("Consts")
                || token.StartsWith("UsersDmm"))
            {
                // Индексы пропускаем
                return;
            }
            
            if (token == MetadataTokens.Fld || token == MetadataTokens.LineNo)
            {
                if (!infoBase.Properties.ContainsKey(fullKey))
                {
                    var propertyObject = Configurator.CreateProperty(uuid, token, code);
                    infoBase.Properties.Add(fullKey, propertyObject);
                    if (propertyObject.FileName != Guid.Empty)
                    {
                        if (!infoBase.PropertiesById.ContainsKey(propertyObject.FileName))
                            infoBase.PropertiesById.Add(propertyObject.FileName, propertyObject);
                    }
                }

                return;
            }
            
            Type type = Configurator.GetTypeByToken(token);
            ApplicationObject metaObject = Configurator.CreateObject(uuid, token, code);
            if (metaObject == null) return; // unsupported type of metadata object

            if (token == MetadataTokens.VT)
            {
                if (!infoBase.TableParts.ContainsKey(fullKey))
                {
                    infoBase.TableParts.Add(fullKey, metaObject);
                    if (metaObject.FileName != Guid.Empty)
                    {
                        if(!infoBase.TablePartsById.ContainsKey(metaObject.FileName))
                            infoBase.TablePartsById.Add(metaObject.FileName, metaObject);
                    }
                }
                return;
            }

            if (token == MetadataTokens.AccumRgT)
            {
                if(infoBase.AllObjectsById.TryGetValue(metaObject.FileName, out ApplicationObject foundObject))
                {
                    foundObject.NestedObjects.Add(metaObject);
                }

                return;
            }

            if (!infoBase.AllTypes.TryGetValue(type, out Dictionary<string, ApplicationObject> collection))
            {
                return; // unsupported collection of metadata objects
            }

            if (!collection.ContainsKey(fullKey))
            {
                collection.Add(fullKey, metaObject);
                if (metaObject.FileName != Guid.Empty)
                {
                    if (!infoBase.AllObjectsById.ContainsKey(metaObject.FileName))
                        infoBase.AllObjectsById.Add(metaObject.FileName, metaObject);
                }
            }
        }
    }
}