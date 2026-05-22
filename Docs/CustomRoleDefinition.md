# Azure Custom Role: SQL Backup Blob Writer (No Delete)

## Overview
This custom Azure RBAC role grants a SQL Server Managed Identity the minimum permissions needed to perform backup and restore operations against Azure Blob Storage, while **explicitly denying blob deletion**. Backup file cleanup is handled by Azure Blob Storage lifecycle policies, not by SQL Server.

## Prerequisites
Before creating this role, gather the following values:

| Placeholder | Description | Example |
|---|---|---|
| `<your-subscription-id>` | Azure subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `<your-resource-group>` | Resource group containing the storage account | `rg-prod-backups` |
| `<mystorageaccount>` | Storage account name for backups | `redazprodechobackups` |

## Role Definitions

There are two variants depending on whether SQL Server needs management plane read access.

### Option 1: Data Plane Only (Minimal)
Use this when SQL Server only needs to read/write backup blobs and does **not** need to list containers or read storage account metadata.

```json
{
  "Name": "SQL Backup Blob Writer No Delete",
  "Description": "Allows SQL Server Managed Identity to read and write blobs but not delete",
  "Actions": [],
  "NotActions": [],
  "DataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action",
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action"
  ],
  "NotDataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete"
  ],
  "AssignableScopes": [
    "/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group>/providers/Microsoft.Storage/storageAccounts/<mystorageaccount>"
  ]
}
```

### Option 2: Data Plane + Management Plane Read (Recommended)
Use this when SQL Server also needs to read storage account properties, list blob services, and list containers. This is the **recommended** option as it allows SQL Server to discover backup destinations.

```json
{
  "Name": "SQL Backup Blob Writer No Delete",
  "Description": "Allows SQL Server Managed Identity to read and write blobs but not delete",
  "Actions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/read",
    "Microsoft.Storage/storageAccounts/blobServices/read",
    "Microsoft.Storage/storageAccounts/read"
  ],
  "NotActions": [],
  "DataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action",
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action"
  ],
  "NotDataActions": [
    "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete"
  ],
  "AssignableScopes": [
    "/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group>/providers/Microsoft.Storage/storageAccounts/<mystorageaccount>"
  ]
}
```

## Permission Breakdown

### Actions (Management Plane)
| Permission | Purpose |
|---|---|
| `storageAccounts/read` | Read storage account properties |
| `blobServices/read` | Read blob service configuration |
| `blobServices/containers/read` | List and read container metadata |

> Only included in Option 2.

### DataActions (Data Plane - Allowed)
| Permission | Purpose |
|---|---|
| `blobs/read` | Read backup files (required for restore operations) |
| `blobs/write` | Write and overwrite backup files |
| `blobs/add/action` | Create new backup blobs |
| `blobs/move/action` | Move or rename blobs |

### NotDataActions (Data Plane - Denied)
| Permission | Purpose |
|---|---|
| `blobs/delete` | **Explicitly blocked** — prevents accidental or malicious deletion of backup files |

## How to Deploy

### Step 1: Create the custom role
Save the JSON definition above to a file (e.g. `role-definition.json`), replacing the placeholders, then run:

```bash
az role definition create --role-definition role-definition.json
```

### Step 2: Assign the role to the SQL Server Managed Identity
```bash
az role assignment create \
  --assignee <sql-server-managed-identity-object-id> \
  --role "SQL Backup Blob Writer No Delete" \
  --scope "/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group>/providers/Microsoft.Storage/storageAccounts/<mystorageaccount>"
```

### Step 3: Verify the assignment
```bash
az role assignment list \
  --assignee <sql-server-managed-identity-object-id> \
  --scope "/subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group>/providers/Microsoft.Storage/storageAccounts/<mystorageaccount>" \
  --output table
```

## Security Notes
- This role follows the **principle of least privilege** — only the permissions required for backup/restore are granted.
- Blob deletion is explicitly denied. Backup file cleanup is managed by **Azure Blob Storage lifecycle policies** (see backup documentation for retention periods).
- The `AssignableScopes` restricts this role to a **single storage account**. To reuse across multiple storage accounts, add additional scopes or scope to the resource group/subscription level.
