using System;
using System.Collections.Generic;

namespace YPermitin.SQLCLR.YellowMetadataReader.Models
{
    public sealed class ConfigObject
    {
        public List<object> Values { get; } = new List<object>();

        public int GetInt32(int[] path)
        {
            if (path.Length == 1)
            {
                return int.Parse((string)Values[path[0]]);
            }

            int i = 0;
            List<object> values = Values;
            do
            {
                values = ((ConfigObject)values[path[i]]).Values;
                i++;
            }
            while (i < path.Length - 1);

            return int.Parse((string)values[path[i]]);
        }
        public Guid GetUuid(int[] path)
        {
            return new Guid(GetString(path));
        }
        public string GetString(int[] path)
        {
            if (path.Length == 1)
            {
                return (string)Values[path[0]];
            }

            int i = 0;
            List<object> values = Values;
            do
            {
                values = ((ConfigObject)values[path[i]]).Values;
                i++;
            }
            while (i < path.Length - 1);

            return (string)values[path[i]];
        }
        public ConfigObject GetObject(int[] path)
        {
            if (path.Length == 1)
            {
                return (ConfigObject)Values[path[0]];
            }

            int i = 0;
            List<object> values = Values;
            do
            {
                values = ((ConfigObject)values[path[i]]).Values;
                i++;
            }
            while (i < path.Length - 1);

            return (ConfigObject)values[path[i]];
        }
                
        public DiffObject CompareTo(ConfigObject target)
        {
            DiffObject diff = new DiffObject()
            {
                Path = string.Empty,
                SourceValue = this,
                TargetValue = target,
                DiffKind = DiffKind.None
            };

            CompareObjects(this, target, diff);

            return diff;
        }
        private void CompareObjects(ConfigObject source, ConfigObject target, DiffObject diff)
        {
            int sourceCount = source.Values.Count;
            int targetCount = target.Values.Count;
            int count = Math.Min(sourceCount, targetCount);

            ConfigObject mdSource;
            ConfigObject mdTarget;
            for (int i = 0; i < count; i++) // update
            {
                mdSource = source.Values[i] as ConfigObject;
                mdTarget = target.Values[i] as ConfigObject;

                if (mdSource != null && mdTarget != null)
                {
                    DiffObject newDiff = CreateDiff(diff, DiffKind.Update, mdSource, mdTarget, i);
                    CompareObjects(mdSource, mdTarget, newDiff);
                    if (newDiff.DiffObjects.Count > 0)
                    {
                        diff.DiffObjects.Add(newDiff);
                    }
                }
                else if (mdSource != null || mdTarget != null)
                {
                    diff.DiffObjects.Add(
                            CreateDiff(
                                diff, DiffKind.Update, source.Values[i], target.Values[i], i));
                }
                else
                {
                    if ((string)source.Values[i] != (string)target.Values[i])
                    {
                        diff.DiffObjects.Add(
                            CreateDiff(
                                diff, DiffKind.Update, source.Values[i], target.Values[i], i));
                    }
                }
            }

            if (sourceCount > targetCount) // delete
            {
                for (int i = count; i < sourceCount; i++)
                {
                    diff.DiffObjects.Add(
                        CreateDiff(
                            diff, DiffKind.Delete, source.Values[i], null, i));
                }
            }
            else if (targetCount > sourceCount) // insert
            {
                for (int i = count; i < targetCount; i++)
                {
                    diff.DiffObjects.Add(
                        CreateDiff(
                            diff, DiffKind.Insert, null, target.Values[i], i));
                }
            }
        }
        private DiffObject CreateDiff(DiffObject parent, DiffKind kind, object source, object target, int path)
        {
            return new DiffObject()
            {
                Path = parent.Path + (string.IsNullOrEmpty(parent.Path) ? string.Empty : ".") + path.ToString(),
                SourceValue = source,
                TargetValue = target,
                DiffKind = kind
            };
        }
    }
}