{ }:

{
  global = {
    tolerations = [ ];
    nodeSelector = { };
    cattle = {
      systemDefaultRegistry = "";
      windowsCluster = {
        enabled = false;
        tolerations = [
          {
            key = "cattle.io/os";
            value = "linux";
            effect = "NoSchedule";
            operator = "Equal";
          }
        ];
        nodeSelector = {
          "kubernetes.io/os" = "linux";
        };
        defaultSetting = {
          taintToleration = "cattle.io/os=linux:NoSchedule";
          systemManagedComponentsNodeSelector = "kubernetes.io/os:linux";
        };
      };
    };
  };
  networkPolicies = {
    enabled = false;
    type = "k3s";
  };
  image = {
    longhorn = {
      engine = {
        repository = "longhornio/longhorn-engine";
        tag = "v1.9.0";
      };
      manager = {
        repository = "longhornio/longhorn-manager";
        tag = "v1.9.0";
      };
      ui = {
        repository = "longhornio/longhorn-ui";
        tag = "v1.9.0";
      };
      instanceManager = {
        repository = "longhornio/longhorn-instance-manager";
        tag = "v1.9.0";
      };
      shareManager = {
        repository = "longhornio/longhorn-share-manager";
        tag = "v1.9.0";
      };
      backingImageManager = {
        repository = "longhornio/backing-image-manager";
        tag = "v1.9.0";
      };
      supportBundleKit = {
        repository = "longhornio/support-bundle-kit";
        tag = "v0.0.55";
      };
    };
    csi = {
      attacher = {
        repository = "longhornio/csi-attacher";
        tag = "v4.8.1";
      };
      provisioner = {
        repository = "longhornio/csi-provisioner";
        tag = "v5.2.0";
      };
      nodeDriverRegistrar = {
        repository = "longhornio/csi-node-driver-registrar";
        tag = "v2.13.0";
      };
      resizer = {
        repository = "longhornio/csi-resizer";
        tag = "v1.13.2";
      };
      snapshotter = {
        repository = "longhornio/csi-snapshotter";
        tag = "v8.2.0";
      };
      livenessProbe = {
        repository = "longhornio/livenessprobe";
        tag = "v2.15.0";
      };
    };
    openshift = {
      oauthProxy = {
        repository = "";
        tag = "";
      };
    };
    pullPolicy = "IfNotPresent";
  };
  service = {
    ui = {
      type = "ClusterIP";
      nodePort = null;
    };
    manager = {
      type = "ClusterIP";
      nodePort = "";
    };
  };
  persistence = {
    defaultClass = true;
    defaultFsType = "ext4";
    defaultMkfsParams = "";
    defaultClassReplicaCount = 3;
    defaultDataLocality = "disabled";
    reclaimPolicy = "Delete";
    volumeBindingMode = "Immediate";
    migratable = false;
    disableRevisionCounter = "true";
    nfsOptions = "";
    recurringJobSelector = {
      enable = false;
      jobList = [ ];
    };
    backingImage = {
      enable = false;
      name = null;
      dataSourceType = null;
      dataSourceParameters = null;
      expectedChecksum = null;
    };
    defaultDiskSelector = {
      enable = false;
      selector = "";
    };
    defaultNodeSelector = {
      enable = false;
      selector = "";
    };
    removeSnapshotsDuringFilesystemTrim = "ignored";
    dataEngine = "v1";
    backupTargetName = "default";
  };
  preUpgradeChecker = {
    jobEnabled = true;
    upgradeVersionCheck = true;
  };
  csi = {
    kubeletRootDir = null;
    attacherReplicaCount = null;
    provisionerReplicaCount = null;
    resizerReplicaCount = null;
    snapshotterReplicaCount = null;
  };
  defaultSettings = {
    allowRecurringJobWhileVolumeDetached = null;
    createDefaultDiskLabeledNodes = null;
    defaultDataPath = null;
    defaultDataLocality = null;
    replicaSoftAntiAffinity = null;
    replicaAutoBalance = null;
    storageOverProvisioningPercentage = null;
    storageMinimalAvailablePercentage = null;
    storageReservedPercentageForDefaultDisk = null;
    upgradeChecker = null;
    upgradeResponderURL = null;
    defaultReplicaCount = null;
    defaultLonghornStaticStorageClass = null;
    failedBackupTTL = null;
    backupExecutionTimeout = null;
    restoreVolumeRecurringJobs = null;
    recurringSuccessfulJobsHistoryLimit = null;
    recurringFailedJobsHistoryLimit = null;
    recurringJobMaxRetention = null;
    supportBundleFailedHistoryLimit = null;
    taintToleration = null;
    systemManagedComponentsNodeSelector = null;
    priorityClass = "longhorn-critical";
    autoSalvage = null;
    autoDeletePodWhenVolumeDetachedUnexpectedly = null;
    disableSchedulingOnCordonedNode = null;
    replicaZoneSoftAntiAffinity = null;
    replicaDiskSoftAntiAffinity = null;
    nodeDownPodDeletionPolicy = null;
    nodeDrainPolicy = null;
    detachManuallyAttachedVolumesWhenCordoned = null;
    replicaReplenishmentWaitInterval = null;
    concurrentReplicaRebuildPerNodeLimit = null;
    concurrentVolumeBackupRestorePerNodeLimit = null;
    disableRevisionCounter = "true";
    systemManagedPodsImagePullPolicy = null;
    allowVolumeCreationWithDegradedAvailability = null;
    autoCleanupSystemGeneratedSnapshot = null;
    autoCleanupRecurringJobBackupSnapshot = null;
    concurrentAutomaticEngineUpgradePerNodeLimit = null;
    backingImageCleanupWaitInterval = null;
    backingImageRecoveryWaitInterval = null;
    guaranteedInstanceManagerCPU = null;
    kubernetesClusterAutoscalerEnabled = null;
    orphanResourceAutoDeletion = null;
    orphanResourceAutoDeletionGracePeriod = null;
    storageNetwork = null;
    deletingConfirmationFlag = true;
    engineReplicaTimeout = null;
    snapshotDataIntegrity = null;
    snapshotDataIntegrityImmediateCheckAfterSnapshotCreation = null;
    snapshotDataIntegrityCronjob = null;
    removeSnapshotsDuringFilesystemTrim = null;
    fastReplicaRebuildEnabled = null;
    replicaFileSyncHttpClientTimeout = null;
    longGRPCTimeOut = null;
    logLevel = null;
    backupCompressionMethod = null;
    backupConcurrentLimit = null;
    restoreConcurrentLimit = null;
    v1DataEngine = null;
    v2DataEngine = null;
    v2DataEngineHugepageLimit = null;
    v2DataEngineGuaranteedInstanceManagerCPU = null;
    v2DataEngineCPUMask = null;
    allowEmptyNodeSelectorVolume = null;
    allowEmptyDiskSelectorVolume = null;
    allowCollectingLonghornUsageMetrics = null;
    disableSnapshotPurge = null;
    snapshotMaxCount = null;
    v2DataEngineLogLevel = null;
    v2DataEngineLogFlags = null;
    v2DataEngineSnapshotDataIntegrity = null;
    freezeFilesystemForSnapshot = null;
    autoCleanupSnapshotWhenDeleteBackup = null;
    autoCleanupSnapshotAfterOnDemandBackupCompleted = null;
    rwxVolumeFastFailover = null;
    offlineRelicaRebuilding = null;
  };
  defaultBackupStore = {
    backupTarget = null;
    backupTargetCredentialSecret = null;
    pollInterval = null;
  };
  privateRegistry = {
    createSecret = null;
    registryUrl = null;
    registryUser = null;
    registryPasswd = null;
    registrySecret = null;
  };
  longhornManager = {
    log = {
      format = "plain";
    };
    priorityClass = "longhorn-critical";
    tolerations = [ ];
    nodeSelector = { };
    serviceAnnotations = { };
  };
  longhornDriver = {
    log = {
      format = "plain";
    };
    priorityClass = "longhorn-critical";
    tolerations = [ ];
    nodeSelector = { };
  };
  longhornUI = {
    replicas = 2;
    priorityClass = "longhorn-critical";
    affinity = {
      podAntiAffinity = {
        preferredDuringSchedulingIgnoredDuringExecution = [
          {
            weight = 1;
            podAffinityTerm = {
              labelSelector = {
                matchExpressions = [
                  {
                    key = "app";
                    operator = "In";
                    values = [ "longhorn-ui" ];
                  }
                ];
              };
              topologyKey = "kubernetes.io/hostname";
            };
          }
        ];
      };
    };
    tolerations = [ ];
    nodeSelector = { };
  };
  ingress = {
    ingressClassName = null;
    enabled = true;
    # TODO: make this configurable?
    host = "longhorn.home.mattprovost.dev";
    tls = false;
    secureBackends = false;
    tlsSecret = "longhorn.local-tls";
    path = "/";
    pathType = "ImplementationSpecific";
    annotations = null;
    secrets = null;
  };
  enablePSP = false;
  namespaceOverride = "";
  annotations = { };
  serviceAccount = {
    annotations = { };
  };
  metrics = {
    serviceMonitor = {
      enabled = false;
      additionalLabels = { };
      annotations = { };
      interval = "";
      scrapeTimeout = "";
      relabelings = [ ];
      metricRelabelings = [ ];
    };
  };
  openshift = {
    enabled = false;
    ui = {
      route = "longhorn-ui";
      port = 443;
      proxy = 8443;
    };
  };
  enableGoCoverDir = false;
  extraObjects = [ ];
}
