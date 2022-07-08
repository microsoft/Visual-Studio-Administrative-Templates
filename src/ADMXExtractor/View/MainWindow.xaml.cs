// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System.Diagnostics;
using System;
using System.Windows;
using System.Windows.Forms;
using System.IO;

namespace ADMXExtractor
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private const string AdmxDirectoryName = "admx";
        private const string NonLocalizableWindowTitle = "Visual Studio Administrative Templates";
        private const string WinDirEnvironmentVariable = "WinDir";
        private const string PolicyDefinitionsDirectoryName = "PolicyDefinitions";

        public MainWindow()
        {
            InitializeComponent();
            Title = NonLocalizableWindowTitle;
            LicenseTermsTitle.Text = Strings.LicenseTermsTitle;
            LicenseTerms.Text = Strings.LicenseTermsText;
            LicenseTermsCheckBox.Content = Strings.LicenseTermsCheckBoxText;
            LicenseTermsContinueButton.Content = Strings.LicenseTermsContinueButtonText;
            LicenseTermsContinueButton.IsEnabled = false;

            SetUncheckedButton();
        }

        private void LicenseTermsCheckBox_Checked(object sender, RoutedEventArgs e)
        {
            // When checked, enable the "Continue" Button
            LicenseTermsContinueButton.IsEnabled = true;
            LicenseTermsContinueButton.Focusable = true;
            LicenseTermsContinueButton.Opacity = 1;
        }

        private void LicenseTermsCheckBox_Unchecked(object sender, RoutedEventArgs e)
        {
            SetUncheckedButton();
        }

        private void SetUncheckedButton()
        {
            // When checked, enable the "Continue" Button
            LicenseTermsContinueButton.IsEnabled = false;
            LicenseTermsContinueButton.Focusable = false;
            LicenseTermsContinueButton.Opacity = .5;
        }

        private void LicenseTermsContinueButton_Click(object sender, RoutedEventArgs e)
        {
            Hide();

            var browseForFolder = new FolderBrowserDialog();
            browseForFolder.RootFolder = Environment.SpecialFolder.MyComputer;

            var winDirPath = Environment.GetEnvironmentVariable(WinDirEnvironmentVariable);
            var policyDefinitionPath = Path.Combine(winDirPath, PolicyDefinitionsDirectoryName);
            browseForFolder.SelectedPath = Directory.Exists(policyDefinitionPath) ? policyDefinitionPath : winDirPath;

            browseForFolder.Description = Strings.BrowseForFolderDescriptionText;

            if (browseForFolder.ShowDialog() is System.Windows.Forms.DialogResult.OK)
            {
                // Extract the ADMX and ADSM files to the selected directory.
                var source = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, AdmxDirectoryName);
                var selected = browseForFolder.SelectedPath;

                string messageBoxText;
                MessageBoxImage messageBoxImage;
                try
                {
                    ProcessXcopy(source, selected);

                    messageBoxText = Strings.FileExtractionSuccess;
                    messageBoxImage = (MessageBoxImage)MessageBoxIcon.Information;
                }
                catch (Exception ex)
                {
                    messageBoxText = string.Format(Strings.FileExtractionFailure, ex.Message);
                    messageBoxImage = (MessageBoxImage)MessageBoxIcon.Warning;
                }

                System.Windows.MessageBox.Show(messageBoxText, NonLocalizableWindowTitle, MessageBoxButton.OK, messageBoxImage, MessageBoxResult.OK);
            }

            Close();
        }

        /// <summary>
        /// Xcopy files and folders from bin to the targetDirectory
        /// </summary>
        /// <remarks>
        /// /d: [:MM-DD-YYYY] Copies source files changed on or after the specified date only. If you do not include a MM-DD-YYYY value, xcopy
        ///     copies all Source files that are newer than existing Destination files. This command-line option allows you to update files that have changed.
        /// /s: Copies directories and subdirectories, unless they are empty. If you omit /s, xcopy works within a single directory.
        /// /i: If Source is a directory or contains wildcards and Destination does not exist, xcopy assumes Destination
        ///     specifies a directory name and creates a new directory. Then, xcopy copies all specified files into the new directory. 
        ///     By default, xcopy prompts you to specify whether Destination is a file or a directory.
        /// </remarks>
        /// <param name="source"></param>
        /// <param name="destination"></param>
        private void ProcessXcopy(string source, string destination)
        {
            ProcessStartInfo startInfo = new ProcessStartInfo()
            {
                Arguments = $"\"{source}\" \"{destination}\" /d /s /i",
                CreateNoWindow = false,
                FileName = "xcopy",
                UseShellExecute = false,
                WindowStyle = ProcessWindowStyle.Hidden,
            };

            using (Process exeProcess = Process.Start(startInfo))
            {
                exeProcess.WaitForExit();
            }
        }
    }
}
