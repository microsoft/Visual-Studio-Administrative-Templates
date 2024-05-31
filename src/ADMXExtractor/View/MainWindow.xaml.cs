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
        private const string PolicyDefinitionsDirectoryName = "PolicyDefinitions";

        public MainWindow()
        {
            InitializeComponent();
            Title = NonLocalizableWindowTitle;
            LicenseTermsTitle.Text = Strings.LicenseTermsTitle;
            LicenseTerms.Text = Strings.LicenseTermsText;
            LicenseTermsCheckBoxTextBlock.Text = Strings.LicenseTermsCheckBoxText;
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

            using var browseForFolder = new FolderBrowserDialog();
            browseForFolder.RootFolder = Environment.SpecialFolder.MyComputer;

            var winDirPath = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            var policyDefinitionPath = Path.Combine(winDirPath, PolicyDefinitionsDirectoryName);
            browseForFolder.SelectedPath = Directory.Exists(policyDefinitionPath) ? policyDefinitionPath : winDirPath;

            browseForFolder.Description = Strings.BrowseForFolderDescriptionText;
            
            string messageBoxText;
            MessageBoxImage messageBoxImage;
            
            var dialogResult = browseForFolder.ShowDialog();
            if (dialogResult.Equals(System.Windows.Forms.DialogResult.Cancel) || dialogResult.Equals(System.Windows.Forms.DialogResult.Abort))
            {
                // If the user closes or aborts the FolderBrowserDialog by clicking "Cancel" or by clicking the "X" in the upper right corner,
                // exit the application.
                messageBoxText = string.Format(Strings.FileExtractionCancel);
                messageBoxImage = (MessageBoxImage)MessageBoxIcon.Information;
            }
            else
            {
                // Extract the ADMX and ADSM files to the selected directory.
                var source = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, AdmxDirectoryName);
                var selected = browseForFolder.SelectedPath;

                try
                {
                    CopyFiles(source, selected);
                    messageBoxText = Strings.FileExtractionSuccess;
                    messageBoxImage = (MessageBoxImage)MessageBoxIcon.Information;
                }
                catch (Exception ex)
                {
                    messageBoxText = string.Format(Strings.FileExtractionFailure, ex.Message);
                    messageBoxImage = (MessageBoxImage)MessageBoxIcon.Warning;
                }
            }

            System.Windows.MessageBox.Show(messageBoxText, NonLocalizableWindowTitle, MessageBoxButton.OK, messageBoxImage, MessageBoxResult.OK);
            Close();
        }

        /// <summary>
        /// Copy files and folders from the source directory to the destination directory
        /// </summary>
        /// <param name="source">The path to the source folder to copy.</param>
        /// <param name="destination">The path to the destination folder.</param>
        private void CopyFiles(string sourceDir, string destinationDir)
        {
            // Get information about the source directory
            var dir = new DirectoryInfo(sourceDir);

            // Check if the source directory exists
            if (!dir.Exists)
                throw new DirectoryNotFoundException($"Source directory not found: {dir.FullName}");

            // Cache directories before we start copying
            var dirs = dir.GetDirectories();

            // Create the destination directory
            Directory.CreateDirectory(destinationDir);

            // Get the files in the source directory and copy to the destination directory
            foreach (FileInfo file in dir.GetFiles())
            {
                string targetFilePath = Path.Combine(destinationDir, file.Name);
                file.CopyTo(targetFilePath, overwrite: true);
            }

            // If recursive and copying subdirectories, recursively call this method
            foreach (DirectoryInfo subDir in dirs)
            {
                string newDestinationDir = Path.Combine(destinationDir, subDir.Name);
                CopyFiles(subDir.FullName, newDestinationDir);
            }
        }
    }
}
