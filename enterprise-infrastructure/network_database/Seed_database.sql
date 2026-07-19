-- ==========================================================
-- SEEDING DATA FOR THE NETWORK STATION DATABASE (SCHEMA B)
-- ==========================================================

USE The_Network_Station_Database;

-- 1. Populate Node Types (Layer must be an Integer)
INSERT INTO node_type (type_name, layer) VALUES
('Core Router', 3),
('Distribution Switch', 3),
('Access Switch', 2),
('Next-Gen Firewall', 3);

-- 2. Populate Central Device Inventory 
-- Status matches ENUM values: 'ONLINE','DEGRADED','OFFLINE','MAINTENANCE'
INSERT INTO device_network (hostname, type_id, mac_address, operating_status) VALUES
('GOTH-CORE-GW01', 1, '00:50:56:A1:B2:C3', 'ONLINE'),
('GOTH-DIST-SW01', 2, '00:50:56:B3:C4:D5', 'ONLINE'),
('GOTH-ACC-SW03', 3, '00:50:56:C5:D6:E7', 'DEGRADED'),
('GOTH-EDGE-FW01', 4, '00:50:56:D7:E8:F9', 'ONLINE');

-- 3. Populate IP Network Allocations (Linked via device_id)
INSERT INTO ip_assignment (device_id, ip_address, subnet_mask, default_gateway, vlan_id) VALUES
(1, '10.200.1.1', '255.255.255.252', '10.200.1.2', 1),
(2, '10.200.1.10', '255.255.255.0', '10.200.1.1', 99),
(3, '10.200.2.31', '255.255.255.0', '10.200.2.1', 10),
(4, '10.200.0.254', '255.255.255.240', '10.200.0.241', 99);

-- 4. Populate Telemetry Logs (Metric Values use Decimal)
INSERT INTO telemetry_log (device_id, metric_type, metric_value, status_code) VALUES
(1, 'CPU_Utilization', 14.50, 'OK'),
(2, 'Memory_Usage', 42.10, 'OK'),
(3, 'Interface_Errors', 88.00, 'WARN_CRC'),
(4, 'Active_Sessions', 55.20, 'OK');

-- 5. Populate Engine Simulation Logs for Automation Tracking
INSERT INTO automation_incident (device_id, incident_description, action_taken, resolution_status) VALUES
(3, 'Flapping MAC address detected on interface GigabitEthernet0/3.', 'Port isolated via automation script.', 'RESOLVED'),
(1, 'BGP neighbor relationship lost: HoldTimer expired.', 'Triggered core link failover route.', 'OPEN'),
(4, 'Security policy rulebase out of sync with central registry.', 'Executed local configurations audit.', 'RESOLVED');
