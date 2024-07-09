# Bash scripts

## get_general_info.bash

The script collects basic information about the file being analysed. The path (as argument `-i` or `--input-file`) to the file is required.

**Usage**:

```bash
bash get_general_info.bash -i /path/to/the/file
```

OR

```bash
bash get_general_info.bash --input-file /path/to/the/file
```

The script checks for directories (artifacts, malicious, output) in the folder where the file is located. All output is stored in the **output** directory.

> **Note**: You'll need to add the API keys for VirusTotal, Tria.ge, and AlienVault to the configuration file for the malwoverview.py tool (https://github.com/alexandreborges/malwoverview) so that it can work with the malwoverview.py tool.

---
