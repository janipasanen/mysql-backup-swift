# MySQL Backup Swift

A lightweight, high-performance CLI tool written in Swift for automating MySQL database backups, rotation, and cloud storage.

## Features

- **Automated Backups**: Performs `mysqldump` of specified databases.
- **Backup Rotation**: 
  - Maintains a local history of backups.
  - Automatically compresses backups older than the current day into `.tar.gz` format to save space.
- **Retention Policy**: Automatically deletes backups older than a configurable number of days (e.g., 1, 30, 360, 720 days).
- **Google Drive Integration**: Securely uploads backups to Google Drive using a provided access token.
- **Flexible Configuration**: Supports both command-line arguments and environment variables.
- **Swift 5.3 Compatible**: Specifically engineered to run on x86_64 architectures and older Swift toolchains.

## Installation

Ensure you have Swift 5.3+ installed.

```bash
git clone https://github.com/janipasanen/mysql-backup-swift.git
cd mysql-backup-swift
swift build -c release
```

The binary will be located at `.build/release/mysql-backup-swift`.

## Usage

### Command Line Arguments

```bash
./.build/release/mysql-backup-swift \
  --user myuser \
  --password mypass \
  --database my_db \
  --directory ./my_backups \
  --retention 30 \
  --gd-token "your_google_drive_token" \
  --gd-folder "your_folder_id"
```

### Environment Variables

Alternatively, you can configure the tool using environment variables:

```bash
export MYSQL_USER="myuser"
export MYSQL_PASSWORD="mypass"
export MYSQL_DATABASE="my_db"
export GD_TOKEN="your_google_drive_token"
export GD_FOLDER="your_folder_id"

./.build/release/mysql-backup-swift
```

### Available Options

| Option | Short | Env Var | Description | Default |
| :--- | :--- | :--- | :--- | :--- |
| `--user` | `-u` | `MYSQL_USER` | MySQL username | Required |
| `--password` | `-p` | `MYSQL_PASSWORD` | MySQL password | Optional |
| `--database` | `-d` | `MYSQL_DATABASE` | Name of the database | Required |
| `--directory` | `-o` | `MYSQL_BACKUP_DIR` | Local backup directory | `./backups` |
| `--retention` | `-r` | `MYSQL_RETENTION_DAYS` | Days to keep backups | `30` |
| `--gd-token` | `-t` | `GD_TOKEN` | Google Drive Access Token | Optional |
| `--gd-folder` | `-f` | `GD_FOLDER` | Google Drive Folder ID | Optional |
| `--help` | `-h` | N/A | Show this help message | N/A |

## Examples

### 1. Local Backup with 7-day retention
```bash
./mysql-backup-swift -u root -d production_db -r 7 -o ./backups/prod
```

### 2. Full Cloud Backup (Daily)
Set your environment variables and run:
```bash
./mysql-backup-swift --database customer_data --retention 365
```

## Testing
Run the test suite to verify rotation and retention logic:
```bash
swift test
```
