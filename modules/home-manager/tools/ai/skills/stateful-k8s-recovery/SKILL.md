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
