/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.6-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: 10.10.0.5    Database: network_statistics
-- ------------------------------------------------------
-- Server version	8.4.6

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `ap_connection_lost_daily_fact`
--

DROP TABLE IF EXISTS `ap_connection_lost_daily_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ap_connection_lost_daily_fact` (
  `date_key` int NOT NULL,
  `ap_key` int NOT NULL,
  `ip_key` int NOT NULL,
  `lost_cnt` int NOT NULL,
  PRIMARY KEY (`date_key`,`ap_key`,`ip_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ap_dim`
--

DROP TABLE IF EXISTS `ap_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ap_dim` (
  `ap_key` int NOT NULL AUTO_INCREMENT,
  `ap_mac` bigint NOT NULL,
  `ap_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ap_key`),
  UNIQUE KEY `search` (`ap_mac`,`ap_name`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ap_reboot_cnt_per_week_fact`
--

DROP TABLE IF EXISTS `ap_reboot_cnt_per_week_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ap_reboot_cnt_per_week_fact` (
  `date_key` int NOT NULL,
  `ap_key` int NOT NULL,
  `ip_key` int NOT NULL,
  `count_reboot` int NOT NULL,
  PRIMARY KEY (`date_key`,`ap_key`,`ip_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_ap_info_archive`
--

DROP TABLE IF EXISTS `aruba_iap_ap_info_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_ap_info_archive` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `ap_mac` bigint NOT NULL,
  `ap_name` varchar(255) DEFAULT NULL,
  `ap_ip` int NOT NULL,
  `ap_model` varchar(255) NOT NULL,
  `ap_uptime_seconds` bigint NOT NULL,
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(`poll_time`))
(PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p9999 VALUES LESS THAN (9999) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_ap_info_stg`
--

DROP TABLE IF EXISTS `aruba_iap_ap_info_stg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_ap_info_stg` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `ap_mac` bigint NOT NULL,
  `ap_name` varchar(255) DEFAULT NULL,
  `ap_ip` int NOT NULL,
  `ap_model` varchar(255) NOT NULL,
  `ap_uptime_seconds` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_ap_info_stg_ingest`
--

DROP TABLE IF EXISTS `aruba_iap_ap_info_stg_ingest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_ap_info_stg_ingest` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `ap_mac` bigint NOT NULL,
  `ap_name` varchar(255) DEFAULT NULL,
  `ap_ip` int NOT NULL,
  `ap_model` varchar(255) NOT NULL,
  `ap_uptime_seconds` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_device_info_archive`
--

DROP TABLE IF EXISTS `aruba_iap_device_info_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_device_info_archive` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `device_mac` bigint NOT NULL,
  `device_wlan_mac` bigint DEFAULT NULL,
  `device_ip` int NOT NULL,
  `device_ap_ip` int DEFAULT NULL,
  `device_name` varchar(255) DEFAULT NULL,
  `device_rx` bigint NOT NULL,
  `device_tx` bigint NOT NULL,
  `device_snr` int DEFAULT NULL,
  `device_uptime_seconds` bigint DEFAULT NULL,
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(`poll_time`))
(PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p9999 VALUES LESS THAN (9999) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_device_info_stg`
--

DROP TABLE IF EXISTS `aruba_iap_device_info_stg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_device_info_stg` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `device_mac` bigint NOT NULL,
  `device_wlan_mac` bigint DEFAULT NULL,
  `device_ip` int NOT NULL,
  `device_ap_ip` int DEFAULT NULL,
  `device_name` varchar(255) DEFAULT NULL,
  `device_rx` bigint NOT NULL,
  `device_tx` bigint NOT NULL,
  `device_snr` int DEFAULT NULL,
  `device_uptime_seconds` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_device_info_stg_ingest`
--

DROP TABLE IF EXISTS `aruba_iap_device_info_stg_ingest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_device_info_stg_ingest` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `device_mac` bigint NOT NULL,
  `device_wlan_mac` bigint DEFAULT NULL,
  `device_ip` int NOT NULL,
  `device_ap_ip` int DEFAULT NULL,
  `device_name` varchar(255) DEFAULT NULL,
  `device_rx` bigint NOT NULL,
  `device_tx` bigint NOT NULL,
  `device_snr` int DEFAULT NULL,
  `device_uptime_seconds` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_wlan_traffic_archive`
--

DROP TABLE IF EXISTS `aruba_iap_wlan_traffic_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_wlan_traffic_archive` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `wlan_ap_mac` bigint NOT NULL,
  `wlan_essid` varchar(255) NOT NULL,
  `wlan_mac` bigint NOT NULL,
  `wlan_tx` bigint NOT NULL,
  `wlan_rx` bigint NOT NULL,
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(`poll_time`))
(PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p9999 VALUES LESS THAN (9999) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_wlan_traffic_stg`
--

DROP TABLE IF EXISTS `aruba_iap_wlan_traffic_stg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_wlan_traffic_stg` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `wlan_ap_mac` bigint NOT NULL,
  `wlan_essid` varchar(255) NOT NULL,
  `wlan_mac` bigint NOT NULL,
  `wlan_tx` bigint NOT NULL,
  `wlan_rx` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `aruba_iap_wlan_traffic_stg_ingest`
--

DROP TABLE IF EXISTS `aruba_iap_wlan_traffic_stg_ingest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `aruba_iap_wlan_traffic_stg_ingest` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `wlan_ap_mac` bigint NOT NULL,
  `wlan_essid` varchar(255) NOT NULL,
  `wlan_mac` bigint NOT NULL,
  `wlan_tx` bigint NOT NULL,
  `wlan_rx` bigint NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `connection_status_dim`
--

DROP TABLE IF EXISTS `connection_status_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `connection_status_dim` (
  `status` varchar(20) NOT NULL,
  `id` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `date_dim`
--

DROP TABLE IF EXISTS `date_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `date_dim` (
  `date_key` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  PRIMARY KEY (`date_key`),
  UNIQUE KEY `search` (`date`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_auth_data_web`
--

DROP TABLE IF EXISTS `device_auth_data_web`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_auth_data_web` (
  `data_class` varchar(255) DEFAULT NULL,
  `data` longtext CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `temp_data` longtext CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `id` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  KEY `device_auth_web_data_class_IDX` (`data_class`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_dim`
--

DROP TABLE IF EXISTS `device_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_dim` (
  `device_key` int NOT NULL AUTO_INCREMENT,
  `device_mac` bigint NOT NULL,
  `device_name` varchar(255) DEFAULT NULL,
  `device_iface_wifi` tinyint NOT NULL,
  PRIMARY KEY (`device_key`),
  UNIQUE KEY `search` (`device_iface_wifi`,`device_mac`,`device_name`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_traffic_by_hour_fact`
--

DROP TABLE IF EXISTS `device_traffic_by_hour_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_traffic_by_hour_fact` (
  `date_key` int NOT NULL,
  `time_key` int NOT NULL,
  `device_key` int NOT NULL,
  `transmission_bytes` bigint NOT NULL,
  PRIMARY KEY (`date_key`,`time_key`,`device_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_wlan_connections_fact`
--

DROP TABLE IF EXISTS `device_wlan_connections_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_wlan_connections_fact` (
  `date_key` int NOT NULL,
  `time_key` int NOT NULL,
  `device_key` int NOT NULL,
  `device_ip_key` int NOT NULL,
  `ap_key` int NOT NULL,
  `iface_key` int NOT NULL,
  `vendor_key` int NOT NULL,
  `ap_vendor_key` int NOT NULL,
  `cnt_status_key` int NOT NULL,
  `event_timestamp` bigint DEFAULT NULL,
  PRIMARY KEY (`date_key`,`time_key`,`device_key`,`device_ip_key`,`ap_key`,`iface_key`,`vendor_key`,`ap_vendor_key`,`cnt_status_key`),
  KEY `device_wlan_connections_fact_device_key_IDX` (`device_key`,`event_timestamp` DESC) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_wlan_metrics_fact`
--

DROP TABLE IF EXISTS `device_wlan_metrics_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_wlan_metrics_fact` (
  `date_key` int NOT NULL,
  `time_key` int NOT NULL,
  `device_key` int NOT NULL,
  `snr` int NOT NULL,
  PRIMARY KEY (`date_key`,`time_key`,`device_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `device_wlan_uptime_fact`
--

DROP TABLE IF EXISTS `device_wlan_uptime_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_wlan_uptime_fact` (
  `device_key` int NOT NULL,
  `ip_key` int NOT NULL,
  `uptime_seconds` bigint NOT NULL,
  PRIMARY KEY (`device_key`,`ip_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gw_iface_dim`
--

DROP TABLE IF EXISTS `gw_iface_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `gw_iface_dim` (
  `iface_key` int NOT NULL AUTO_INCREMENT,
  `iface_mac` bigint NOT NULL,
  `iface_name` varchar(255) DEFAULT NULL,
  `iface_phy_name` varchar(255) DEFAULT NULL,
  `iface_remark` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`iface_key`),
  UNIQUE KEY `search` (`iface_mac`,`iface_phy_name`,`iface_name`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 COMMENT='for iface table, name means wifi essid string (if detected), if no essid detected, use iface_phy_name (eth0,eth1)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `iface_traffic_by_hour_fact`
--

DROP TABLE IF EXISTS `iface_traffic_by_hour_fact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `iface_traffic_by_hour_fact` (
  `date_key` int NOT NULL,
  `time_key` int NOT NULL,
  `iface_key` int NOT NULL,
  `transmission_bytes` bigint NOT NULL,
  PRIMARY KEY (`date_key`,`time_key`,`iface_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `igate_gw240_status_wifi_station_archive`
--

DROP TABLE IF EXISTS `igate_gw240_status_wifi_station_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `igate_gw240_status_wifi_station_archive` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(`poll_time`))
(PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p9999 VALUES LESS THAN (9999) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `igate_gw240_status_wifi_station_stg`
--

DROP TABLE IF EXISTS `igate_gw240_status_wifi_station_stg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `igate_gw240_status_wifi_station_stg` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `igate_gw240_status_wifi_station_stg_ingest`
--

DROP TABLE IF EXISTS `igate_gw240_status_wifi_station_stg_ingest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `igate_gw240_status_wifi_station_stg_ingest` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ip_dim`
--

DROP TABLE IF EXISTS `ip_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ip_dim` (
  `ip_key` int NOT NULL AUTO_INCREMENT,
  `ipv4` int DEFAULT NULL,
  `ipv6` bigint DEFAULT NULL,
  PRIMARY KEY (`ip_key`),
  UNIQUE KEY `search4` (`ipv4`) USING BTREE,
  UNIQUE KEY `search6` (`ipv6`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rfc1213_iftable_traffic_archive`
--

DROP TABLE IF EXISTS `rfc1213_iftable_traffic_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rfc1213_iftable_traffic_archive` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `if_index` int NOT NULL,
  `if_descr` varchar(255) NOT NULL,
  `if_phys_address` bigint NOT NULL,
  `if_admin_status` enum('1','2','3') NOT NULL,
  `if_oper_status` enum('1','2','3') NOT NULL,
  `if_in_octets` bigint NOT NULL,
  `if_out_octets` bigint NOT NULL,
  `ip_ad_ent_addr` int DEFAULT NULL,
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(`poll_time`))
(PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p9999 VALUES LESS THAN (9999) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rfc1213_iftable_traffic_stg`
--

DROP TABLE IF EXISTS `rfc1213_iftable_traffic_stg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rfc1213_iftable_traffic_stg` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `if_index` int NOT NULL,
  `if_descr` varchar(255) NOT NULL,
  `if_phys_address` bigint NOT NULL,
  `if_admin_status` enum('1','2','3') NOT NULL,
  `if_oper_status` enum('1','2','3') NOT NULL,
  `if_in_octets` bigint NOT NULL,
  `if_out_octets` bigint NOT NULL,
  `ip_ad_ent_addr` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rfc1213_iftable_traffic_stg_ingest`
--

DROP TABLE IF EXISTS `rfc1213_iftable_traffic_stg_ingest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rfc1213_iftable_traffic_stg_ingest` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `if_index` int NOT NULL,
  `if_descr` varchar(255) NOT NULL,
  `if_phys_address` bigint NOT NULL,
  `if_admin_status` enum('1','2','3') NOT NULL,
  `if_oper_status` enum('1','2','3') NOT NULL,
  `if_in_octets` bigint NOT NULL,
  `if_out_octets` bigint NOT NULL,
  `ip_ad_ent_addr` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `time_dim`
--

DROP TABLE IF EXISTS `time_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `time_dim` (
  `time_key` int NOT NULL AUTO_INCREMENT,
  `time` int NOT NULL,
  PRIMARY KEY (`time_key`),
  UNIQUE KEY `search` (`time`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tplink_deco_client_device_wlan_archive`
--

DROP TABLE IF EXISTS `tplink_deco_client_device_wlan_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tplink_deco_client_device_wlan_archive` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(`poll_time`))
(PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p9999 VALUES LESS THAN (9999) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tplink_deco_client_device_wlan_stg`
--

DROP TABLE IF EXISTS `tplink_deco_client_device_wlan_stg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tplink_deco_client_device_wlan_stg` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tplink_deco_client_device_wlan_stg_ingest`
--

DROP TABLE IF EXISTS `tplink_deco_client_device_wlan_stg_ingest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tplink_deco_client_device_wlan_stg_ingest` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tplink_deco_device_info_archive`
--

DROP TABLE IF EXISTS `tplink_deco_device_info_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tplink_deco_device_info_archive` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1
/*!50100 PARTITION BY RANGE (year(`poll_time`))
(PARTITION p2025 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p9999 VALUES LESS THAN (9999) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tplink_deco_device_info_stg`
--

DROP TABLE IF EXISTS `tplink_deco_device_info_stg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tplink_deco_device_info_stg` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tplink_deco_device_info_stg_ingest`
--

DROP TABLE IF EXISTS `tplink_deco_device_info_stg_ingest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tplink_deco_device_info_stg_ingest` (
  `id` int NOT NULL AUTO_INCREMENT,
  `poll_time` datetime NOT NULL,
  `raw_data` json DEFAULT NULL COMMENT 'use json to handle schema change',
  PRIMARY KEY (`id`,`poll_time`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_dim`
--

DROP TABLE IF EXISTS `vendor_dim`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_dim` (
  `vendor_key` int NOT NULL AUTO_INCREMENT,
  `vendor_prefix` int NOT NULL,
  `vendor_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`vendor_key`),
  UNIQUE KEY `search` (`vendor_prefix`) USING BTREE
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'network_statistics'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-08-03 22:17:52
