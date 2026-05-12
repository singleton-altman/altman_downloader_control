import 'package:freezed_annotation/freezed_annotation.dart';

part 'qb_preferences_model.freezed.dart';
part 'qb_preferences_model.g.dart';

/// qBittorrent Preferences 模型
/// 用于 /api/v2/app/preferences 接口
@freezed
class QBPreferencesModel with _$QBPreferencesModel {
  const factory QBPreferencesModel({
    @JsonKey(name: 'add_stopped_enabled')
    @Default(false)
    bool addStoppedEnabled,
    @JsonKey(name: 'add_to_top_of_queue') @Default(false) bool addToTopOfQueue,
    @JsonKey(name: 'add_trackers') @Default('') String addTrackers,
    @JsonKey(name: 'add_trackers_enabled')
    @Default(false)
    bool addTrackersEnabled,
    @JsonKey(name: 'add_trackers_from_url_enabled')
    @Default(false)
    bool addTrackersFromUrlEnabled,
    @JsonKey(name: 'add_trackers_url') @Default('') String addTrackersUrl,
    @JsonKey(name: 'add_trackers_url_list')
    @Default('')
    String addTrackersUrlList,
    @JsonKey(name: 'alt_dl_limit') @Default(0) int altDlLimit,
    @JsonKey(name: 'alt_up_limit') @Default(0) int altUpLimit,
    @JsonKey(name: 'alternative_webui_enabled')
    @Default(false)
    bool alternativeWebuiEnabled,
    @JsonKey(name: 'alternative_webui_path')
    @Default('')
    String alternativeWebuiPath,
    @JsonKey(name: 'announce_ip') @Default('') String announceIp,
    @JsonKey(name: 'announce_port') @Default(0) int announcePort,
    @JsonKey(name: 'announce_to_all_tiers')
    @Default(true)
    bool announceToAllTiers,
    @JsonKey(name: 'announce_to_all_trackers')
    @Default(false)
    bool announceToAllTrackers,
    @JsonKey(name: 'anonymous_mode') @Default(false) bool anonymousMode,
    @JsonKey(name: 'app_instance_name') @Default('') String appInstanceName,
    @JsonKey(name: 'async_io_threads') @Default(10) int asyncIoThreads,
    @JsonKey(name: 'auto_delete_mode') @Default(0) int autoDeleteMode,
    @JsonKey(name: 'auto_tmm_enabled') @Default(false) bool autoTmmEnabled,
    @JsonKey(name: 'autorun_enabled') @Default(false) bool autorunEnabled,
    @JsonKey(name: 'autorun_on_torrent_added_enabled')
    @Default(false)
    bool autorunOnTorrentAddedEnabled,
    @JsonKey(name: 'autorun_on_torrent_added_program')
    @Default('')
    String autorunOnTorrentAddedProgram,
    @JsonKey(name: 'autorun_program') @Default('') String autorunProgram,
    @JsonKey(name: 'banned_IPs') @Default('') String bannedIPs,
    @JsonKey(name: 'bdecode_depth_limit') @Default(100) int bdecodeDepthLimit,
    @JsonKey(name: 'bdecode_token_limit')
    @Default(10000000)
    int bdecodeTokenLimit,
    @JsonKey(name: 'bittorrent_protocol') @Default(0) int bittorrentProtocol,
    @JsonKey(name: 'block_peers_on_privileged_ports')
    @Default(false)
    bool blockPeersOnPrivilegedPorts,
    @JsonKey(name: 'bypass_auth_subnet_whitelist')
    @Default('')
    String bypassAuthSubnetWhitelist,
    @JsonKey(name: 'bypass_auth_subnet_whitelist_enabled')
    @Default(false)
    bool bypassAuthSubnetWhitelistEnabled,
    @JsonKey(name: 'bypass_local_auth') @Default(false) bool bypassLocalAuth,
    @JsonKey(name: 'category_changed_tmm_enabled')
    @Default(false)
    bool categoryChangedTmmEnabled,
    @JsonKey(name: 'checking_memory_use') @Default(32) int checkingMemoryUse,
    @JsonKey(name: 'confirm_torrent_deletion')
    @Default(true)
    bool confirmTorrentDeletion,
    @JsonKey(name: 'confirm_torrent_recheck')
    @Default(true)
    bool confirmTorrentRecheck,
    @JsonKey(name: 'connection_speed') @Default(30) int connectionSpeed,
    @JsonKey(name: 'current_interface_address')
    @Default('')
    String currentInterfaceAddress,
    @JsonKey(name: 'current_interface_name')
    @Default('')
    String currentInterfaceName,
    @JsonKey(name: 'current_network_interface')
    @Default('')
    String currentNetworkInterface,
    @JsonKey(name: 'delete_torrent_content_files')
    @Default(false)
    bool deleteTorrentContentFiles,
    @JsonKey(name: 'dht') @Default(true) bool dht,
    @JsonKey(name: 'dht_bootstrap_nodes')
    @Default(
      'dht.libtorrent.org:25401, dht.transmissionbt.com:6881, router.bittorrent.com:6881',
    )
    String dhtBootstrapNodes,
    @JsonKey(name: 'disk_cache') @Default(-1) int diskCache,
    @JsonKey(name: 'disk_cache_ttl') @Default(60) int diskCacheTtl,
    @JsonKey(name: 'disk_io_read_mode') @Default(1) int diskIoReadMode,
    @JsonKey(name: 'disk_io_type') @Default(0) int diskIoType,
    @JsonKey(name: 'disk_io_write_mode') @Default(1) int diskIoWriteMode,
    @JsonKey(name: 'disk_queue_size') @Default(1048576) int diskQueueSize,
    @JsonKey(name: 'dl_limit') @Default(0) int dlLimit,
    @JsonKey(name: 'dont_count_slow_torrents')
    @Default(false)
    bool dontCountSlowTorrents,
    @JsonKey(name: 'dyndns_domain')
    @Default('changeme.dyndns.org')
    String dyndnsDomain,
    @JsonKey(name: 'dyndns_enabled') @Default(false) bool dyndnsEnabled,
    @JsonKey(name: 'dyndns_password') @Default('') String dyndnsPassword,
    @JsonKey(name: 'dyndns_service') @Default(0) int dyndnsService,
    @JsonKey(name: 'dyndns_username') @Default('') String dyndnsUsername,
    @JsonKey(name: 'embedded_tracker_port')
    @Default(9000)
    int embeddedTrackerPort,
    @JsonKey(name: 'embedded_tracker_port_forwarding')
    @Default(false)
    bool embeddedTrackerPortForwarding,
    @JsonKey(name: 'enable_coalesce_read_write')
    @Default(false)
    bool enableCoalesceReadWrite,
    @JsonKey(name: 'enable_os_cache') bool? enableOsCache,
    @JsonKey(name: 'enable_embedded_tracker')
    @Default(false)
    bool enableEmbeddedTracker,
    @JsonKey(name: 'enable_multi_connections_from_same_ip')
    @Default(false)
    bool enableMultiConnectionsFromSameIp,
    @JsonKey(name: 'enable_piece_extent_affinity')
    @Default(false)
    bool enablePieceExtentAffinity,
    @JsonKey(name: 'enable_upload_suggestions')
    @Default(false)
    bool enableUploadSuggestions,
    @JsonKey(name: 'encryption') @Default(0) int encryption,
    @JsonKey(name: 'excluded_file_names') @Default('') String excludedFileNames,
    @JsonKey(name: 'excluded_file_names_enabled')
    @Default(false)
    bool excludedFileNamesEnabled,
    @JsonKey(name: 'export_dir') @Default('') String exportDir,
    @JsonKey(name: 'export_dir_fin') @Default('') String exportDirFin,
    @JsonKey(name: 'file_log_age') @Default(1) int fileLogAge,
    @JsonKey(name: 'file_log_age_type') @Default(1) int fileLogAgeType,
    @JsonKey(name: 'file_log_backup_enabled')
    @Default(true)
    bool fileLogBackupEnabled,
    @JsonKey(name: 'file_log_delete_old') @Default(true) bool fileLogDeleteOld,
    @JsonKey(name: 'file_log_enabled') @Default(true) bool fileLogEnabled,
    @JsonKey(name: 'file_log_max_size') @Default(65) int fileLogMaxSize,
    @JsonKey(name: 'file_log_path')
    @Default('/config/qBittorrent/logs')
    String fileLogPath,
    @JsonKey(name: 'file_pool_size') @Default(100) int filePoolSize,
    @JsonKey(name: 'hashing_threads') @Default(1) int hashingThreads,
    @JsonKey(name: 'hostname_cache_ttl')
    @Default(1200)
    int hostnameCacheTtl,
    @JsonKey(name: 'i2p_address') @Default('127.0.0.1') String i2pAddress,
    @JsonKey(name: 'i2p_enabled') @Default(false) bool i2pEnabled,
    @JsonKey(name: 'i2p_inbound_length') @Default(3) int i2pInboundLength,
    @JsonKey(name: 'i2p_inbound_quantity') @Default(3) int i2pInboundQuantity,
    @JsonKey(name: 'i2p_mixed_mode') @Default(false) bool i2pMixedMode,
    @JsonKey(name: 'i2p_outbound_length') @Default(3) int i2pOutboundLength,
    @JsonKey(name: 'i2p_outbound_quantity') @Default(3) int i2pOutboundQuantity,
    @JsonKey(name: 'i2p_port') @Default(7656) int i2pPort,
    @JsonKey(name: 'idn_support_enabled')
    @Default(false)
    bool idnSupportEnabled,
    @JsonKey(name: 'ignore_ssl_errors') @Default(false) bool ignoreSslErrors,
    @JsonKey(name: 'incomplete_files_ext')
    @Default(true)
    bool incompleteFilesExt,
    @JsonKey(name: 'ip_filter_enabled') @Default(false) bool ipFilterEnabled,
    @JsonKey(name: 'ip_filter_path') @Default('') String ipFilterPath,
    @JsonKey(name: 'ip_filter_trackers') @Default(false) bool ipFilterTrackers,
    @JsonKey(name: 'limit_lan_peers') @Default(true) bool limitLanPeers,
    @JsonKey(name: 'limit_tcp_overhead') @Default(false) bool limitTcpOverhead,
    @JsonKey(name: 'limit_utp_rate') @Default(true) bool limitUtpRate,
    @JsonKey(name: 'listen_port') @Default(47868) int listenPort,
    @JsonKey(name: 'locale') @Default('zh_CN') String locale,
    @JsonKey(name: 'lsd') @Default(true) bool lsd,
    @JsonKey(name: 'mail_notification_auth_enabled')
    @Default(true)
    bool mailNotificationAuthEnabled,
    @JsonKey(name: 'mail_notification_email')
    @Default('')
    String mailNotificationEmail,
    @JsonKey(name: 'mail_notification_enabled')
    @Default(false)
    bool mailNotificationEnabled,
    @JsonKey(name: 'mail_notification_password')
    @Default('')
    String mailNotificationPassword,
    @JsonKey(name: 'mail_notification_sender')
    @Default('qBittorrent_notification@example.com')
    String mailNotificationSender,
    @JsonKey(name: 'mail_notification_smtp')
    @Default('smtp.changeme.com')
    String mailNotificationSmtp,
    @JsonKey(name: 'mail_notification_ssl_enabled')
    @Default(false)
    bool mailNotificationSslEnabled,
    @JsonKey(name: 'mail_notification_encryption_type')
    @Default('')
    String mailNotificationEncryptionType,
    @JsonKey(name: 'mail_notification_username')
    @Default('')
    String mailNotificationUsername,
    @JsonKey(name: 'mark_of_the_web') @Default(true) bool markOfTheWeb,
    @JsonKey(name: 'max_active_checking_torrents')
    @Default(1)
    int maxActiveCheckingTorrents,
    @JsonKey(name: 'max_active_downloads') @Default(3) int maxActiveDownloads,
    @JsonKey(name: 'max_active_torrents') @Default(5) int maxActiveTorrents,
    @JsonKey(name: 'max_active_uploads') @Default(3) int maxActiveUploads,
    @JsonKey(name: 'max_concurrent_http_announces')
    @Default(50)
    int maxConcurrentHttpAnnounces,
    @JsonKey(name: 'max_connec') @Default(500) int maxConnec,
    @JsonKey(name: 'max_connec_per_torrent')
    @Default(100)
    int maxConnecPerTorrent,
    @JsonKey(name: 'max_inactive_seeding_time')
    @Default(-1)
    int maxInactiveSeedingTime,
    @JsonKey(name: 'max_inactive_seeding_time_enabled')
    @Default(false)
    bool maxInactiveSeedingTimeEnabled,
    @JsonKey(name: 'max_ratio') @Default(-1.0) double maxRatio,
    @JsonKey(name: 'max_ratio_act') @Default(0) int maxRatioAct,
    @JsonKey(name: 'max_ratio_enabled') @Default(false) bool maxRatioEnabled,
    @JsonKey(name: 'max_seeding_time') @Default(-1) int maxSeedingTime,
    @JsonKey(name: 'max_seeding_time_enabled')
    @Default(false)
    bool maxSeedingTimeEnabled,
    @JsonKey(name: 'max_uploads') @Default(20) int maxUploads,
    @JsonKey(name: 'max_uploads_per_torrent')
    @Default(4)
    int maxUploadsPerTorrent,
    @JsonKey(name: 'memory_working_set_limit')
    @Default(512)
    int memoryWorkingSetLimit,
    @JsonKey(name: 'merge_trackers') @Default(false) bool mergeTrackers,
    @JsonKey(name: 'outgoing_ports_max') @Default(0) int outgoingPortsMax,
    @JsonKey(name: 'outgoing_ports_min') @Default(0) int outgoingPortsMin,
    @JsonKey(name: 'peer_tos') @Default(4) int peerTos,
    @JsonKey(name: 'peer_turnover') @Default(4) int peerTurnover,
    @JsonKey(name: 'peer_turnover_cutoff') @Default(90) int peerTurnoverCutoff,
    @JsonKey(name: 'peer_turnover_interval')
    @Default(300)
    int peerTurnoverInterval,
    @JsonKey(name: 'performance_warning')
    @Default(false)
    bool performanceWarning,
    @JsonKey(name: 'pex') @Default(true) bool pex,
    @JsonKey(name: 'preallocate_all') @Default(false) bool preallocateAll,
    @JsonKey(name: 'proxy_auth_enabled') @Default(false) bool proxyAuthEnabled,
    @JsonKey(name: 'proxy_bittorrent') @Default(true) bool proxyBittorrent,
    @JsonKey(name: 'proxy_hostname_lookup')
    @Default(false)
    bool proxyHostnameLookup,
    @JsonKey(name: 'proxy_ip') @Default('') String proxyIp,
    @JsonKey(name: 'proxy_misc') @Default(true) bool proxyMisc,
    @JsonKey(name: 'proxy_password') @Default('') String proxyPassword,
    @JsonKey(name: 'proxy_peer_connections')
    @Default(false)
    bool proxyPeerConnections,
    @JsonKey(name: 'proxy_torrents_only') bool? proxyTorrentsOnly,
    @JsonKey(name: 'proxy_port') @Default(8080) int proxyPort,
    @JsonKey(name: 'proxy_rss') @Default(true) bool proxyRss,

    /// qB 4.6+ 使用数字枚举；旧版本可能返回字符串
    @JsonKey(name: 'proxy_type') Object? proxyType,
    @JsonKey(name: 'proxy_username') @Default('') String proxyUsername,
    @JsonKey(name: 'python_executable_path')
    @Default('')
    String pythonExecutablePath,
    @JsonKey(name: 'queueing_enabled') @Default(true) bool queueingEnabled,
    @JsonKey(name: 'random_port') @Default(false) bool randomPort,
    @JsonKey(name: 'reannounce_when_address_changed')
    @Default(false)
    bool reannounceWhenAddressChanged,
    @JsonKey(name: 'recheck_completed_torrents')
    @Default(false)
    bool recheckCompletedTorrents,
    @JsonKey(name: 'refresh_interval') @Default(1500) int refreshInterval,
    @JsonKey(name: 'request_queue_size') @Default(500) int requestQueueSize,
    @JsonKey(name: 'resolve_peer_countries')
    @Default(true)
    bool resolvePeerCountries,
    @JsonKey(name: 'resolve_peer_host_names')
    @Default(false)
    bool resolvePeerHostNames,
    @JsonKey(name: 'resume_data_storage_type')
    @Default('Legacy')
    String resumeDataStorageType,
    @JsonKey(name: 'rss_auto_downloading_enabled')
    @Default(false)
    bool rssAutoDownloadingEnabled,
    @JsonKey(name: 'rss_download_repack_proper_episodes')
    @Default(true)
    bool rssDownloadRepackProperEpisodes,
    @JsonKey(name: 'rss_fetch_delay') @Default(2) int rssFetchDelay,
    @JsonKey(name: 'rss_max_articles_per_feed')
    @Default(50)
    int rssMaxArticlesPerFeed,
    @JsonKey(name: 'rss_processing_enabled')
    @Default(true)
    bool rssProcessingEnabled,
    @JsonKey(name: 'rss_refresh_interval') @Default(30) int rssRefreshInterval,
    @JsonKey(name: 'rss_smart_episode_filters')
    @Default(
      's(\\d+)e(\\d+)\n(\\d+)x(\\d+)\n(\\d{4}[.\\-]\\d{1,2}[.\\-]\\d{1,2})\n(\\d{1,2}[.\\-]\\d{1,2}[.\\-]\\d{4})',
    )
    String rssSmartEpisodeFilters,
    @JsonKey(name: 'save_path') @Default('/downloads') String savePath,
    @JsonKey(name: 'save_path_changed_tmm_enabled')
    @Default(false)
    bool savePathChangedTmmEnabled,
    @JsonKey(name: 'save_resume_data_interval')
    @Default(60)
    int saveResumeDataInterval,
    @JsonKey(name: 'save_statistics_interval')
    @Default(15)
    int saveStatisticsInterval,

    /// qB 返回 map（value 可能为数字/字符串），统一转字符串存储以兼容
    @JsonKey(name: 'scan_dirs') @Default({}) Map<String, String> scanDirs,
    @JsonKey(name: 'schedule_from_hour') @Default(8) int scheduleFromHour,
    @JsonKey(name: 'schedule_from_min') @Default(0) int scheduleFromMin,
    @JsonKey(name: 'schedule_to_hour') @Default(20) int scheduleToHour,
    @JsonKey(name: 'schedule_to_min') @Default(0) int scheduleToMin,
    @JsonKey(name: 'scheduler_days') @Default(0) int schedulerDays,
    @JsonKey(name: 'scheduler_enabled') @Default(false) bool schedulerEnabled,
    @JsonKey(name: 'send_buffer_low_watermark')
    @Default(10)
    int sendBufferLowWatermark,
    @JsonKey(name: 'send_buffer_watermark')
    @Default(500)
    int sendBufferWatermark,
    @JsonKey(name: 'send_buffer_watermark_factor')
    @Default(50)
    int sendBufferWatermarkFactor,
    @JsonKey(name: 'slow_torrent_dl_rate_threshold')
    @Default(2)
    int slowTorrentDlRateThreshold,
    @JsonKey(name: 'slow_torrent_inactive_timer')
    @Default(60)
    int slowTorrentInactiveTimer,
    @JsonKey(name: 'slow_torrent_ul_rate_threshold')
    @Default(2)
    int slowTorrentUlRateThreshold,
    @JsonKey(name: 'socket_backlog_size') @Default(30) int socketBacklogSize,
    @JsonKey(name: 'socket_receive_buffer_size')
    @Default(0)
    int socketReceiveBufferSize,
    @JsonKey(name: 'socket_send_buffer_size')
    @Default(0)
    int socketSendBufferSize,
    @JsonKey(name: 'ssl_enabled') @Default(false) bool sslEnabled,
    @JsonKey(name: 'ssl_listen_port') @Default(52983) int sslListenPort,
    @JsonKey(name: 'ssrf_mitigation') @Default(true) bool ssrfMitigation,
    @JsonKey(name: 'status_bar_external_ip')
    @Default(false)
    bool statusBarExternalIp,
    @JsonKey(name: 'stop_tracker_timeout') @Default(2) int stopTrackerTimeout,
    @JsonKey(name: 'temp_path')
    @Default('/downloads/incomplete')
    String tempPath,
    @JsonKey(name: 'temp_path_enabled') @Default(false) bool tempPathEnabled,
    @JsonKey(name: 'torrent_changed_tmm_enabled')
    @Default(true)
    bool torrentChangedTmmEnabled,
    @JsonKey(name: 'torrent_content_layout')
    @Default('Original')
    String torrentContentLayout,
    @JsonKey(name: 'torrent_content_remove_option')
    @Default('Delete')
    String torrentContentRemoveOption,
    @JsonKey(name: 'torrent_file_size_limit')
    @Default(104857600)
    int torrentFileSizeLimit,
    @JsonKey(name: 'torrent_stop_condition')
    @Default('None')
    String torrentStopCondition,
    @JsonKey(name: 'up_limit') @Default(0) int upLimit,
    @JsonKey(name: 'upload_choking_algorithm')
    @Default(1)
    int uploadChokingAlgorithm,
    @JsonKey(name: 'upload_slots_behavior') @Default(0) int uploadSlotsBehavior,
    @JsonKey(name: 'upnp') @Default(false) bool upnp,
    @JsonKey(name: 'upnp_lease_duration') @Default(0) int upnpLeaseDuration,
    @JsonKey(name: 'use_category_paths_in_manual_mode')
    @Default(false)
    bool useCategoryPathsInManualMode,
    @JsonKey(name: 'use_https') @Default(false) bool useHttps,
    @JsonKey(name: 'use_subcategories') @Default(false) bool useSubcategories,
    @JsonKey(name: 'use_unwanted_folder')
    @Default(false)
    bool useUnwantedFolder,
    @JsonKey(name: 'utp_tcp_mixed_mode') @Default(0) int utpTcpMixedMode,
    @JsonKey(name: 'validate_https_tracker_certificate')
    @Default(true)
    bool validateHttpsTrackerCertificate,
    @JsonKey(name: 'web_ui_api_key') @Default('') String webUiApiKey,
    @JsonKey(name: 'web_ui_address') @Default('*') String webUiAddress,
    @JsonKey(name: 'web_ui_ban_duration') @Default(3600) int webUiBanDuration,
    @JsonKey(name: 'web_ui_clickjacking_protection_enabled')
    @Default(true)
    bool webUiClickjackingProtectionEnabled,
    @JsonKey(name: 'web_ui_csrf_protection_enabled')
    @Default(true)
    bool webUiCsrfProtectionEnabled,
    @JsonKey(name: 'web_ui_custom_http_headers')
    @Default('')
    String webUiCustomHttpHeaders,
    @JsonKey(name: 'web_ui_domain_list') @Default('*') String webUiDomainList,
    @JsonKey(name: 'web_ui_host_header_validation_enabled')
    @Default(true)
    bool webUiHostHeaderValidationEnabled,
    @JsonKey(name: 'web_ui_https_cert_path')
    @Default('')
    String webUiHttpsCertPath,
    @JsonKey(name: 'web_ui_https_key_path')
    @Default('')
    String webUiHttpsKeyPath,
    @JsonKey(name: 'web_ui_max_auth_fail_count')
    @Default(5)
    int webUiMaxAuthFailCount,
    @JsonKey(name: 'web_ui_port') @Default(8080) int webUiPort,
    @JsonKey(name: 'web_ui_reverse_proxies_list')
    @Default('')
    String webUiReverseProxiesList,
    @JsonKey(name: 'web_ui_reverse_proxy_enabled')
    @Default(false)
    bool webUiReverseProxyEnabled,
    @JsonKey(name: 'web_ui_secure_cookie_enabled')
    @Default(true)
    bool webUiSecureCookieEnabled,
    @JsonKey(name: 'web_ui_session_timeout')
    @Default(3600)
    int webUiSessionTimeout,
    @JsonKey(name: 'web_ui_upnp') @Default(false) bool webUiUpnp,
    @JsonKey(name: 'web_ui_use_custom_http_headers_enabled')
    @Default(false)
    bool webUiUseCustomHttpHeadersEnabled,
    @JsonKey(name: 'web_ui_username') @Default('admin') String webUiUsername,
  }) = _QBPreferencesModel;

  const QBPreferencesModel._();

  factory QBPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$QBPreferencesModelFromJson(json);
}
