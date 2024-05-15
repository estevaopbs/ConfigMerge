# ConfigMerge

## Table of Contents

- [ConfigMerge](#configmerge)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Contributing](#contributing)
  - [License](#license)

## Description

ConfigMerge is a PowerShell project designed to automate the merging of configuration files in INI, JSON, and XML formats. The project follows specific rules to merge old and new configuration files, ensuring that your configurations are updated without losing any important data.

## Requirements

- PowerShell 7.x 

## Installation

To clone and run this application, you'll need Git and PowerShell installed on your computer. From your command line:

```bash
git clone https://github.com/yourusername/ConfigMerge
cd ConfigMerge
```

## Usage
To use ConfigMerge, you need to have two configuration files: an old one and a new one. The script will merge these two files according to the following rules:

- If a parameter exists in both the old and new config file, the merged file will have this parameter with the value from the old config file.
- If the parameter exists in the new config file and doesn't exist in the old config file, the merged file will have this parameter with the value from the new config file.
- If the parameter exists in the old config file and doesn't exist in the new config file, it will not exist in the merged config file.

To run the script, use the following command in PowerShell:

```pwsh
./ConfigMerge.ps1 -OldFile path_to_old_file -NewFile path_to_new_file -FileType file_type
```

Replace `path_to_old_file` and `path_to_new_file` with the paths to your old and new configuration files, respectively. Replace `file_type` with the type of your configuration files (`ini`, `json`, or `xml`).

## Contributing
We welcome contributions from the community. To contribute:

1. Fork this repository.
2. Create a new feature branch from the master branch.
3. Add your feature or bug fix.
4. Commit your changes, and push the branch to GitHub.
5. Open a pull request with a description of your changes.

## License
ConfigMerge is licensed under the terms of the [MIT License](#LICENSE).