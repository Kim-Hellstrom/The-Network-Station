-- =======================================================
-- ARCHITECTURE: THE NETWORK STATION DATABASE STRUCTURE
-- =======================================================

CREATE TABLE node_type (
    type_id INT AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL,
    layer INT, -- for example Layer 2, 3 etc.. 

    PRIMARY KEY(type_id)
);

CREATE TABLE device_network (
    device_id INT AUTO_INCREMENT,
    hostname VARCHAR(100) NOT NULL UNIQUE,
    type_id INT,
    mac_address VARCHAR(17) NOT NULL UNIQUE, -- Enforces physical layer identification
    operating_status ENUM('ONLINE', 'DEGRADED', 'OFFLINE', 'MAINTENANCE') DEFAULT 'OFFLINE', -- Engine-level validation
    last_audit_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY(device_id)
);

CREATE TABLE ip_assignment (
    assignment_id INT AUTO_INCREMENT,
    device_id INT,
    ip_address VARCHAR(45) NOT NULL,
    subnet_mask VARCHAR(45) NOT NULL,
    default_gateway VARCHAR(45) NOT NULL,
    vlan_id INT DEFAULT 1,

    PRIMARY KEY(assignment_id)
);

CREATE TABLE telemetry_log (
    log_id INT AUTO_INCREMENT,
    device_id INT,
    metric_type VARCHAR(50),
    metric_value DECIMAL(5, 2),
    status_code VARCHAR(20),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY(log_id)
);

CREATE TABLE automation_incident(
    incident_id INT AUTO_INCREMENT,
    device_id INT,
    incident_description VARCHAR(255),
    action_taken VARCHAR(255),
    resolution_status VARCHAR(20), 
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY(incident_id)
);


-- ================================================
-- INTEGRATION MATRIX: FOREIGN KEY RELATIONSHIPS
-- ================================================

ALTER TABLE device_network
ADD FOREIGN KEY(type_id)
REFERENCES node_type(type_id)
ON DELETE SET NULL;

ALTER TABLE ip_assignment
ADD FOREIGN KEY(device_id)
REFERENCES device_network(device_id)
ON DELETE CASCADE;

ALTER TABLE telemetry_log
ADD FOREIGN KEY(device_id)
REFERENCES device_network(device_id)
ON DELETE CASCADE;

ALTER TABLE automation_incident
ADD FOREIGN KEY(device_id)
REFERENCES device_network(device_id)
ON DELETE CASCADE;
