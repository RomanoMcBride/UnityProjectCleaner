# UnityProjectCleaner

Cleans your disk of unity caches that can be re-generated, to free up space from rarely used Unity projects.

<img width="1036" height="836" alt="projectCleaner" src="https://github.com/user-attachments/assets/24f785e8-5525-4838-bf5c-ec1a8e75e4ea" />

# Who is this for?

This is for users that have a lot of small, local Unity projects projects (e.g. samples, tests...) to keep around, but are looking to free disk space.

# Disclaimer

This tool removes files on your local disk. It is designed to only remove files that Unity will re-generate when opening the project again. In order to do that, it needs to make assumptions about the folder structure to identify Unity projects and about what this folder structure contains (critical data or not). Use at your own risk. Always make backups of important data.

# Settings
Using UnityProjectCleaner → Settings opens a menu where the list of files/folders to be removed can be customized.
