---
name: stateful-k8s-recovery
description: >
  Safely back up, restore, or surgically recover Kubernetes stateful workloads.
  Use when manipulating PVC data, testing restores, cloning data volumes, or
  recovering application-specific state such as game worlds, databases, media
  stores, or object-store-backed volumes.
---

# Stateful Kubernetes Recovery

## Goal

Protect irreplaceable data while making recovery progress. Prefer reversible,
verified steps over convenience.

## Rules

1. **Freeze writers first**
   - Scale Deployments/StatefulSets down, stop jobs, or use application-native
     freeze commands before reading or replacing mutable data.
   - Confirm writer pods are gone before mounting a PVC elsewhere.

2. **Preserve current state before replacement**
   - Before overwriting files, copy the current version aside with a timestamped
     name or clone the full PVC.
   - Never delete the only known copy of damaged data during forensics.

3. **Operate from copies**
   - Use scratch PVCs, temporary restore PVCs, or local extracted copies for
     inspection and repair.
   - Keep production PVCs untouched until the recovery candidate is verified.

4. **Verify at multiple layers**
   - Check transport/archive integrity with checksums and format validation.
   - Check application-level structure with domain-specific tools or parsers
     when available.
   - For backup systems, perform a scratch restore before declaring the backup
     usable.

5. **Keep artifacts named and discoverable**
   - Use timestamped PVC, pod, and file names.
   - Report exact paths, PVC names, hashes, and snapshot IDs back to the user.

## Kubernetes PVC workflow

1. Identify the writer workload and PVC.
2. Scale the writer to zero or otherwise freeze writes.
3. Create a backup/scratch PVC with the same storage class and sufficient size.
4. Copy data inside the cluster with both PVCs mounted in a temporary pod.
5. Verify file counts, byte counts, and checksums between source and copy.
6. Detach the copy pod before reusing either PVC elsewhere.
7. Test restores into a scratch PVC before touching production.
8. Restart the writer only after the recovery operation is complete.

## CSI and FUSE mount failures

A node-local CSI mount service can own FUSE processes for application PVCs.
Restarting that service disconnects its active FUSE mounts; applications with
open files cannot safely continue after a `transport endpoint is not connected`
error.

1. Identify the PVC, its `VolumeAttachment`, the node with the staging mount,
   and every pod publishing the volume.
2. Freeze all writers and confirm no publish paths remain before changing a
   disconnected staging mount.
3. Preserve data through the workload's backup or recovery procedure when
   application writes may have been buffered at the time of failure.
4. Let CSI unpublish and unstage the volume after consumers stop. If it remains
   stuck, inspect the node's staging mount and unmount only the confirmed,
   disconnected FUSE mount; never delete a staging directory to force cleanup.
5. Delete a stale `VolumeAttachment` only after confirming that no pod or
   process uses the volume and normal detach has failed.
6. Reattach through CSI, restart the workload, and verify filesystem access,
   application health, and a durable application-level write or save.

Treat maintenance of a node-local mount service as storage maintenance: quiesce
all of that node's PVC consumers before restarting the service.

## Transfer guidance

- Avoid trusting long `kubectl exec ... > file` streams without checksum
  verification.
- `kubectl cp` uses tar over exec and can truncate or fail on unstable streams.
- Prefer creating the archive inside the cluster, serving it with a temporary
  HTTP pod, downloading with retries, and comparing source/destination SHA256.

## Recovery posture

If the user is distressed about potential data loss, slow down. State what has
been frozen, what copies exist, and what the next reversible step is before
making changes.
