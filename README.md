# UnityProjectCleaner

Cleans your disk of unity caches that can be re-generated, to free up space used by rarely used Unity projects.


<img width="1012" height="740" alt="screenshot of the tool showing a list of projects that can be cleaned" src="https://github.com/user-attachments/assets/04773d79-2fb4-42de-8211-2e3587242186" />

# Who is this for?

This is for users that have a lot of small, local Unity projects projects (e.g. samples, tests...) to keep around, but are looking to free disk space.

# Disclaimer

This tool removes files on your local disk. It is designed to only remove files that Unity will re-generate when opening the project again. In order to do that, it needs to make assumptions about the folder structure to identify Unity projects and about what this folder structure contains (critical data or not). Use at your own risk. Always make backups of important data.

# Settings
Using UnityProjectCleaner → Settings opens a menu where the list of files/folders to be removed can be customized.
