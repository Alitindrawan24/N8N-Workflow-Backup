# 🌀 n8n Workflow Backup Automation

This repository provides an automated script to **backup your n8n workflows** into version-controlled JSON files and optionally push them to GitHub.

It uses the official [n8n REST API](https://docs.n8n.io/api/api-reference/) to fetch workflow data and store it neatly under a `/workflows` directory.  
You can configure it to back up **all workflows** or **only active ones**.

## 🚀 Features

- 🔄 Automatically exports all n8n workflows via REST API  
- 🔒 Option to back up only active workflows  
- 💾 Saves each workflow as a separate, prettified JSON file  
- 🧠 Git auto-commit & push with timestamped commit messages  
- 🕒 Easily scheduled via cron for daily/weekly backups  
- 🧱 Safe: no credentials or secrets are stored in the workflow JSON

## 📁 Repository Structure

```
n8n-backup/
├── workflows/ # Folder where JSON workflow backups are stored
├── backup.sh # Main backup script
├── .env # Environment variables (excluded from Git)
└── README.md # This documentation
```


## ⚙️ Requirements

- `bash` (Unix/Linux/macOS environment)
- `curl` — for API requests
- `jq` — for JSON parsing and formatting
- `git` — for versioning and pushing backups

Install `jq` if not already available:
```bash
sudo apt install jq        # Debian/Ubuntu
brew install jq            # macOS
```

## 🔧 Setup Instructions

### 1. Clone this repository
```bash
git clone https://github.com/alitindrawan24/n8n-backup.git
cd n8n-backup
```

### 2. Create a .env file
Copy the contents of `.env.example` and modify it with your actual n8n API credentials and preferences.
```bash
cp .env.example .env
```

> ⚠️ Do not commit .env — it contains sensitive data.
> Make sure your repository is private if you’re using production API keys.

## ▶️ How to Run the Backup

Make the script executable (only once):
```bash
chmod +x backup.sh
```

Then run:
```bash
./backup.sh
```

Example output:
```bash
[backup] Fetching workflow list from n8n...
[backup] Filtering only active workflows...
[backup] Found 3 workflows to backup.
[backup] Saving send-slack-alert-12.json...
[backup] Saving sync-airtable-7.json...
[backup] Saving daily-report-3.json...
[backup] ✅ Backup completed. Files stored in ./workflows
[backup] ✅ Done.
```

## 🕒 Automate with Cron

You can schedule automatic daily backups using cron.

Example (run every day at 1 AM):
```bash
crontab -e
```

Add this line:
```bash
0 1 * * * cd /path/to/n8n-backup && ./backup.sh >> backup.log 2>&1
```

This will:
- Fetch all workflows (or only active ones, depending on .env)
- Commit changes
- Push to GitHub automatically

## 🧩 Restore Workflows

If you ever need to restore a workflow:
1. Open your n8n instance.
2. Go to Workflows → Import from File.
3. Select the corresponding .json file from workflows/.

> The workflow structure will be restored.
> However, credentials must be re-linked manually since they are not stored in the exported JSON.