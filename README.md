# Epic Proxy Script

This repository contains a bash script `epic-proxy.sh` to manage proxy settings
for applications or collections. The script provides a command-line interface
(CLI) to enable or disable proxies and to list information about applications
or collections.

## Usage

### Commands

- `enable [APPNAME|COLLECTIONNAME]`
  - Enables the proxy for the specified application or collection.

- `disable [APPNAME|COLLECTIONNAME|all]`
  - Disables the proxy for the specified application, collection, or all.

- `app list`
  - Lists all applications.

- `app info [APPNAME|COLLECTIONNAME]`
  - Shows information for the specified application or collection.

- `help`
  - Displays the help message.

### Examples

- Enable proxy for an application:
  ```bash
  ./epic-proxy.sh enable global-environment
  ```
- Disable proxy for a collection:
  ```bash
  ./epic-proxy.sh disable debian-8
  ```
- List all applications and collections:
  ```bash
  ./epic-proxy.sh app list
  ```
- Show information for an application or collection:
  ```
  ./epic-proxy.sh app info global-environment
  ```
- Display help mesage:
  ```
  ./epic-proxy.sh help
  ```

