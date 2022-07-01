using System.Diagnostics;
using System;
using System.Windows;
using System.Windows.Forms;
using System.Runtime;
using System.IO;
using ADMXExtractor.View;

namespace ADMXExtractor
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            LicenseTermsTitle.Text = Strings.LicenseTermsTitle;
            LicenseTerms.Text = Strings.LicenseTermsText;
            CheckBoxText.Text = Strings.LicenseTermsCheckBoxText;
            LicenseTermsContinueButton.Content = Strings.LicenseTermsContinueButtonText;
            LicenseTermsContinueButton.IsEnabled = false;
        }

        private void LicenseTermsCheckBox_Checked(object sender, RoutedEventArgs e)
        {
            // When checked, enable the "Continue" Button
            LicenseTermsContinueButton.IsEnabled = true;
        }

        private void LicenseTermsCheckBox_Unchecked(object sender, RoutedEventArgs e)
        {
            // When checked, enable the "Continue" Button
            LicenseTermsContinueButton.IsEnabled = false;
        }

        private void LicenseTermsContinueButton_Click(object sender, RoutedEventArgs e)
        {
            var browseForFolder = new FolderBrowserDialog();
            browseForFolder.Description = Strings.BrowseForFolderDescriptionText;

            if (browseForFolder.ShowDialog() is System.Windows.Forms.DialogResult.OK)
            {
                // Extract the ADMX and ADSM files to the selected directory.
                var source = Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, "admx");
                var selected = browseForFolder.SelectedPath;
                ProcessXcopy(source, selected);
            }
        }

        /// <summary>
        /// Xcopy files and folders from bin to the targetDirectory
        /// </summary>
        /// <remarks>
        /// /d: [:MM-DD-YYYY] Copies source files changed on or after the specified date only. If you do not include a MM-DD-YYYY value, xcopy
        ///     copies all Source files that are newer than existing Destination files. This command-line option allows you to update files that have changed.
        /// /s: Copies directories and subdirectories, unless they are empty. If you omit /s, xcopy works within a single directory.
        /// /e: Copies all subdirectories, even if they are empty. Use /e with the /s and /t command-line options.
        /// /i: If Source is a directory or contains wildcards and Destination does not exist, xcopy assumes Destination
        ///     specifies a directory name and creates a new directory. Then, xcopy copies all specified files into the new directory. 
        ///     By default, xcopy prompts you to specify whether Destination is a file or a directory.
        /// </remarks>
        /// <param name="source"></param>
        /// <param name="destination"></param>
        private void ProcessXcopy(string source, string destination)
        {
            // Use ProcessStartInfo class
            ProcessStartInfo startInfo = new ProcessStartInfo()
            {
                Arguments = $"\"{source}\" \"{destination}\" /d /s /e /i",
                CreateNoWindow = false,
                FileName = "xcopy",
                UseShellExecute = false,
                WindowStyle = ProcessWindowStyle.Hidden,
            };

            try
            {
                using (Process exeProcess = Process.Start(startInfo))
                {
                    exeProcess.WaitForExit();
                }
            }
            catch (Exception exp)
            {
                throw exp;
            }
        }
    }
}
