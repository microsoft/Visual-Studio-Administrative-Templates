using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.IO;
using System.Xml;
using System.Xml.Schema;

namespace UnitTests
{
    [TestClass]
    public class UnitTests
    {
        private static string ADMX_FILE_NAME = "VS2022.admx";
        private static string ADMX_FILE_PATH = @"..\..\..\..\..\..\Visual Studio IDE";
        private static string ADML_FILE_NAME = "VS2022.adml";
        private static string ADML_FILE_PATH = @"..\..\..\..\..\..\Visual Studio IDE\en-US";

        [TestMethod]
        public void CheckAdmxFileExists()
        {
            string admxFullFilePath = Path.Combine(ADMX_FILE_PATH, ADMX_FILE_NAME);
            Assert.IsTrue(File.Exists(admxFullFilePath));
        }

        [TestMethod]
        public void CheckAdmlFileExists()
        {
            string admlFullFilePath = Path.Combine(ADML_FILE_PATH, ADML_FILE_NAME);
            Assert.IsTrue(File.Exists(admlFullFilePath));
        }

        [TestMethod]
        public void CheckAdmxXml()
        {
            string admxFullFilePath = Path.Combine(ADMX_FILE_PATH, ADMX_FILE_NAME);

            try
            {
                XmlReader reader = XmlReader.Create(admxFullFilePath);

                while (reader.Read())
                {
                }
            }
            catch (XmlException e)
            {
                Assert.Fail(e.Message);
            }
        }

        [TestMethod]
        public void CheckAdmlXml()
        {
            string admlFullFilePath = Path.Combine(ADML_FILE_PATH, ADML_FILE_NAME);

            try
            {
                XmlReader reader = XmlReader.Create(admlFullFilePath);

                while (reader.Read())
                {
                }
            }
            catch (XmlException e)
            {
                Assert.Fail(e.Message);
            }
        }
    }
}