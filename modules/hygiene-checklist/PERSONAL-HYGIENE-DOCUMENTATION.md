# Hygiene Checklist Module Documentation

> **Last Updated**: February 5, 2026  
> **Module Path**: `modules/hygiene-checklist/`  
> **Form Number**: Personal Hygiene Form (Employee Health & Hygiene Monitoring)

---

## 📁 File Structure

```
hygiene-checklist/
├── index.js                 # Main module router (routes registration)
├── routes/
│   ├── checklist.js         # Session/checklist CRUD, batch submit, verify
│   ├── employees.js         # Employee CRUD operations
│   ├── checklist-items.js   # Checklist items CRUD + reorder
│   ├── settings.js          # System settings management
│   └── stores.js            # Store CRUD operations
├── views/
│   ├── form.html            # Main checklist form (1774 lines)
│   ├── history.html         # Document history & viewing
│   ├── employees.html       # Employee management page
│   ├── checklist-items.html # Checklist items management
│   └── settings.html        # System settings page
└── sql/
    └── migration-v2-settings-verify.sql  # DB migration script
```

---

## 🗄️ Database Tables

### HygieneChecklistSessions (Document Header)
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK | Auto-increment ID |
| document_number | NVARCHAR(50) | Format: `HYG-YYYYMMDD-NNN` |
| check_date | DATE | Date of the check |
| shift | NVARCHAR(20) | Morning/Afternoon/Night (configurable) |
| checked_by | INT FK | User who created (→ Users.id) |
| total_employees | INT | Total employees checked |
| total_pass | INT | Count passed |
| total_fail | INT | Count failed |
| total_absent | INT | Count absent |
| notes | NVARCHAR(500) | Optional notes |
| verified | BIT | 0=unverified, 1=verified & locked |
| verified_by | INT FK | User who verified (→ Users.id) |
| verified_at | DATETIME | Verification timestamp |
| created_at | DATETIME | Record creation time |

### HygieneChecklists (Employee Check Record)
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK | Auto-increment ID |
| session_id | INT FK | → HygieneChecklistSessions.id |
| employee_id | INT FK | → Employees.id |
| check_date | DATE | Date of check |
| check_time | TIME | Time of check |
| shift | NVARCHAR(20) | Shift name |
| checked_by | INT FK | → Users.id |
| overall_pass | BIT | 1=all items passed |
| is_absent | BIT | 1=employee was absent |
| notes | NVARCHAR(500) | Optional notes |
| created_at | DATETIME | Record creation time |

### HygieneChecklistResponses (Individual Item Responses)
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK | Auto-increment ID |
| checklist_id | INT FK | → HygieneChecklists.id |
| item_id | INT FK | → HygieneChecklistItems.id |
| response | BIT | 1=pass, 0=fail |
| notes | NVARCHAR(500) | Corrective action text |

### HygieneChecklistItems (Configurable Items)
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK | Auto-increment ID |
| name | NVARCHAR(100) | Item name |
| description | NVARCHAR(500) | Optional description |
| is_active | BIT | Soft delete flag |
| sort_order | INT | Display order |
| gender_specific | NVARCHAR(10) | NULL=all, 'Male', 'Female' |
| created_at | DATETIME | Record creation time |
| created_by | INT FK | → Users.id |

### HygieneSettings (Key-Value Settings)
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK | Auto-increment ID |
| setting_key | NVARCHAR(100) | Unique setting name |
| setting_value | NVARCHAR(500) | Setting value |
| updated_by | INT FK | → Users.id |
| updated_at | DATETIME | Last update time |

**Default Settings Keys:**
- `document_prefix` - Default: "HYG"
- `document_title` - Default: "Employee Health and Hygiene Checklist"
- `creation_date` - Document creation date
- `last_revision_date` - Last revision date
- `edition` - Version number
- `company_name` - Company name
- `shifts` - Comma-separated list (e.g., "Morning,Afternoon,Night")

### Employees
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK | Auto-increment ID |
| name | NVARCHAR(100) | Employee name |
| gender | NVARCHAR(10) | 'Male' or 'Female' |
| position | NVARCHAR(100) | Job position |
| store_id | INT FK | → Stores.id (optional) |
| is_active | BIT | Soft delete flag |
| created_by | INT FK | → Users.id |
| created_at | DATETIME | Record creation time |
| updated_at | DATETIME | Last update time |

### Stores
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK | Auto-increment ID |
| name | NVARCHAR(100) | Store name |
| location | NVARCHAR(255) | Store location |
| is_active | BIT | Soft delete flag |
| created_at | DATETIME | Record creation time |

---

## 🔌 API Endpoints

### Base URL: `/hygiene-checklist`

### Sessions (Documents)
| Method | Endpoint | Description | Auth Role |
|--------|----------|-------------|-----------|
| GET | `/api/hygiene-checklists/sessions` | List all sessions with filters | Authenticated |
| GET | `/api/hygiene-checklists/sessions/:id` | Get session with all employee data | Authenticated |
| POST | `/api/hygiene-checklists/batch` | Submit new batch checklist | SuperAuditor, Auditor, Admin |
| PUT | `/api/hygiene-checklists/sessions/:id` | Update session responses | Authenticated |
| PUT | `/api/hygiene-checklists/sessions/:id/verify` | Verify & lock session | SuperAuditor, Admin |
| PUT | `/api/hygiene-checklists/sessions/:id/unverify` | Unlock session | SuperAuditor, Admin |

### Legacy Individual Checklists
| Method | Endpoint | Description | Auth Role |
|--------|----------|-------------|-----------|
| GET | `/api/hygiene-checklists` | List all individual checklists | Authenticated |
| GET | `/api/hygiene-checklists/:id` | Get single checklist with responses | Authenticated |

### Statistics
| Method | Endpoint | Description | Auth Role |
|--------|----------|-------------|-----------|
| GET | `/api/hygiene-checklists/stats/summary` | Get summary stats | Authenticated |

### Employees
| Method | Endpoint | Description | Auth Role |
|--------|----------|-------------|-----------|
| GET | `/api/employees` | List all active employees | Authenticated |
| GET | `/api/employees/:id` | Get single employee | Authenticated |
| POST | `/api/employees` | Create employee | SuperAuditor, Admin |
| PUT | `/api/employees/:id` | Update employee | SuperAuditor, Admin |
| DELETE | `/api/employees/:id` | Soft delete employee | SuperAuditor, Admin |
| GET | `/api/employees/store/:storeId` | Get employees by store | Authenticated |

### Checklist Items
| Method | Endpoint | Description | Auth Role |
|--------|----------|-------------|-----------|
| GET | `/api/checklist-items` | List active items | Authenticated |
| GET | `/api/checklist-items/all` | List all items (inc. inactive) | SuperAuditor, Admin |
| GET | `/api/checklist-items/:id` | Get single item | Authenticated |
| POST | `/api/checklist-items` | Create item | SuperAuditor, Admin |
| PUT | `/api/checklist-items/:id` | Update item | SuperAuditor, Admin |
| DELETE | `/api/checklist-items/:id` | Soft delete item | SuperAuditor, Admin |
| POST | `/api/checklist-items/reorder` | Reorder items | SuperAuditor, Admin |

### Settings
| Method | Endpoint | Description | Auth Role |
|--------|----------|-------------|-----------|
| GET | `/api/settings` | Get all settings as object | Authenticated |
| GET | `/api/settings/all` | Get settings with metadata | SuperAuditor, Admin |
| PUT | `/api/settings` | Batch update settings | SuperAuditor, Admin |
| PUT | `/api/settings/:key` | Update single setting | SuperAuditor, Admin |

### Stores
| Method | Endpoint | Description | Auth Role |
|--------|----------|-------------|-----------|
| GET | `/api/stores` | List active stores | Authenticated |
| GET | `/api/stores/:id` | Get single store | Authenticated |
| POST | `/api/stores` | Create store | Admin |
| PUT | `/api/stores/:id` | Update store | Admin |
| DELETE | `/api/stores/:id` | Soft delete store | Admin |

### Current User
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/me` | Get current logged-in user info |

---

## 📄 Page Routes

| Route | File | Description |
|-------|------|-------------|
| `/hygiene-checklist/` | form.html | Main checklist form |
| `/hygiene-checklist/history` | history.html | Document history |
| `/hygiene-checklist/employees` | employees.html | Employee management |
| `/hygiene-checklist/items` | checklist-items.html | Checklist items config |
| `/hygiene-checklist/settings` | settings.html | System settings |

---

## 🎯 Key Features

### 1. Batch Submission
- All employees checked in single session
- Creates document with auto-generated number (`HYG-YYYYMMDD-NNN`)
- Calculates totals (pass/fail/absent)
- Tracks who checked and when

### 2. Gender-Specific Items
- Items can be marked as Male-only or Female-only
- Shows "N/A" for non-applicable items
- Non-applicable items excluded from pass/fail calculation

### 3. Corrective Action Flow
- When item unchecked → Modal prompts for corrective action
- Must provide corrective action text to proceed
- Corrective action stored with response

### 4. Verification/Locking
- SuperAuditor/Admin can verify documents
- Verified documents are locked from editing
- Can be unverified to allow edits

### 5. Offline Support
- Uses IndexedDB for offline storage
- Caches employees and items locally
- Stores pending submissions
- Auto-syncs when back online

### 6. Draft Saving
- Local storage draft saving
- Key format: `hygiene-draft-{date}-{shift}`
- Prompts to continue draft on page load
- Expires after 24 hours

### 7. Shifts
- Configurable via settings (comma-separated)
- Default: Morning, Afternoon, Night
- Stored in `HygieneSettings.shifts`

---

## 🔄 Data Flow

### Submit Batch Checklist
```
1. Frontend collects: date, shift, employee responses
2. POST /api/hygiene-checklists/batch
3. Creates HygieneChecklistSession record
4. For each employee:
   - Creates HygieneChecklists record
   - For each item: Creates HygieneChecklistResponses record
5. Returns document_number and totals
```

### Verification Flow
```
1. PUT /api/hygiene-checklists/sessions/:id/verify
2. Sets verified=1, verified_by, verified_at
3. Document becomes read-only for non-admins
```

---

## 🎨 UI Components (form.html)

### State Variables
```javascript
let employees = [];           // All active employees
let checklistItems = [];      // All active checklist items
let checklistData = {};       // { empId: { absent: bool, items: { itemId: { checked, corrective, applicable } } } }
let currentCorrectiveEdit = null;  // { empId, itemId }
let isOffline = false;
let offlineDB = null;         // IndexedDB reference
```

### Key Functions
| Function | Description |
|----------|-------------|
| `loadData()` | Loads employees, items, settings |
| `initializeChecklistData()` | Initializes state for all employees |
| `renderTable()` | Renders the checklist table |
| `onCheckChange(empId, itemId, checked)` | Handles checkbox toggle |
| `toggleAbsent(empId)` | Marks employee as absent |
| `openCorrectiveModal(empId, itemId)` | Opens corrective action modal |
| `saveCorrectiveAction()` | Saves corrective action |
| `checkAllPass()` | Checks all applicable items as pass |
| `updateStats()` | Updates summary statistics |
| `validateForm()` | Validates before submit |
| `submitAll()` | Submits the batch checklist |
| `saveDraft()` | Saves to localStorage |
| `loadDraft()` | Loads from localStorage |

---

## 📝 Important Notes

1. **Document Number Format**: `{PREFIX}-{YYYYMMDD}-{SEQ}`
   - Prefix from settings (default: HYG)
   - SEQ is 3-digit zero-padded sequence per day

2. **Soft Delete**: Employees and items use `is_active` flag
   - DELETE endpoints set `is_active = 0`
   - GET endpoints filter `WHERE is_active = 1`

3. **Role Restrictions**:
   - Auditor: Can submit checklists
   - SuperAuditor: Can manage employees, items, settings, verify
   - Admin: Full access

4. **Gender Logic**:
   - `gender_specific = NULL` → Applies to all
   - `gender_specific = 'Male'` → Only for male employees
   - Non-applicable items show as "N/A" in UI

5. **Verification Lock**:
   - Verified documents are locked
   - Only SuperAuditor/Admin can unverify
   - Edit checks `verified` flag before allowing changes

---

## 🔧 Common Modifications

### Add New Checklist Item
1. Go to `/hygiene-checklist/items`
2. Click "Add Item"
3. Enter name, description, sort order
4. Optionally set gender-specific

### Change Shifts
1. Go to `/hygiene-checklist/settings`
2. Edit "Shifts" field (comma-separated)
3. Save settings

### Add New Employee
1. Go to `/hygiene-checklist/employees`
2. Click "Add Employee"
3. Enter name, select gender, optionally set position/store

---

## 🛠️ Database Migrations

Run `sql/migration-v2-settings-verify.sql` to add:
- HygieneSettings table
- verified/verified_by/verified_at columns to sessions
