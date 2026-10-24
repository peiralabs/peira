# PDM and PBS tabs

Two rail tabs sit under Proxmox: **PDM** (Proxmox Datacenter Manager) and
**PBS** (Proxmox Backup Server). Both are optional. Their settings are global,
so they stay the same when you switch connection profiles.

## PDM

PDM shows every cluster it manages in one place:

- **Overview:** each remote's quorum, nodes, CPU and memory. Local storage is
  summed per cluster. Shared storage is listed once and never added to the
  sum, because every node reports the same shared pool.
- **Guests:** one searchable list across all remotes, with start, shutdown,
  stop and reboot. PDM has no reboot endpoint, so reboot is a shutdown
  followed by a start. **Migrate** moves a guest to another remote
  (PDM remote-migrate). The dialog proposes the target's next free VMID, maps
  storage and bridges, and warns that a running container has downtime.
- **Tasks:** recent tasks from every remote, with a Failed filter and log
  tails.

Migrate is refused for two kinds of guest:

- guests tagged `iac`, because a guest managed by infrastructure-as-code
  would drift from its definition;
- containers with raw `lxc.*` config keys (device passthrough), because those
  keys are tied to the source cluster's hardware.

### PDM setup

Settings › PDM takes the URL (port 8443), an API token and, for a
self-signed certificate, its SHA-256 fingerprint. The fingerprint pins the
certificate; leave it empty to use the system CAs.

PDM ships two roles, `Auditor` and `Administrator`:

- `Auditor` on `/` is enough for Overview, Guests and Tasks.
- Power actions and migrate also need `Administrator` on `/resource`. That
  grants guest operations without access to `/access` or `/system`.

PDM then acts through the token it holds for each remote, so those remote
tokens need the matching Proxmox VE privileges too. Receiving a migrated
guest needs `Sys.Incoming` on the target, and a privileged container also
needs `Sys.Modify`.

## PBS

The PBS tab has two server slots (for example an on-site and an off-site
server), with a switcher above the views:

- **Overview:** datastore usage, estimated time until full, and garbage
  collection status.
- **Backups:** namespaces, backup groups and snapshots, with verify,
  protected and encrypted state. Container and host archives can be browsed
  and single files downloaded from the catalog.
- **Jobs:** prune, verify and sync jobs, with run and edit.
- **Tasks:** recent tasks with log tails.

### Two levels of access

Each server stores a **read/verify token**. Give it `Audit` on `/` and
`DatastoreReader` on `/datastore`. With it the app lists everything, reads
notes and catalogs, downloads files, and starts verifies.

Everything that deletes or changes something needs an **unlock**: deleting
snapshots or groups, protecting, editing notes, changing owner, prune,
garbage collection, running prune or sync jobs, and editing jobs. Unlock asks
for the password of the PBS user named in Settings (for example
`user@pbs`). The app exchanges it for a PBS ticket, keeps the ticket in
memory only, and drops it after 30 minutes or when you lock the server. The
password is never stored. That user needs `DatastoreAdmin` on `/datastore`
and `Audit` on `/`. Accounts with two-factor authentication cannot unlock
yet.

### Restore

Whole VMs and containers are restored through the active profile's
Proxmox VE connection, not through PBS. Set **PVE storage** for the slot to
the PVE storage ID that points at this PBS datastore; leave it empty to turn
restore off. Restores always go to an unused VMID and only from the root
namespace. A container keeps the privileged or unprivileged mode it was
backed up with. Raw `lxc.*` keys are skipped, because Proxmox VE accepts them
only from `root@pam`. The Proxmox VE token needs the rights to create guests
on the target storage.

File-level restore from VM disk images is not supported.
