CREATE TABLE players (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  steamId varchar(32) NOT NULL,
  name varchar(64) NOT NULL,
  avatarSmall varchar(255) DEFAULT NULL,
  avatarMedium varchar(255) DEFAULT NULL,
  avatarLarge varchar(255) DEFAULT NULL,
  lastCap timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY idx_players_unique (steamId)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE pointCaps (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  playerId int(10) unsigned NOT NULL,
  playerRole enum('soldier','demoman') NOT NULL,
  pointId int(10) unsigned NOT NULL,
  capsCount int(10) unsigned NOT NULL,
  lastCap timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY idx_pointCaps_unique (playerId,playerRole,pointId)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE points (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  map varchar(64) NOT NULL,
  areaId tinyint(4) NOT NULL,
  areaName varchar(64) NOT NULL,
  scoreSoldier float NOT NULL DEFAULT '0',
  scoreDemoman float NOT NULL DEFAULT '0',
  capsSoldier int(10) unsigned NOT NULL DEFAULT '0',
  capsDemoman int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE KEY idx_points_unique (map,areaId)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DELIMITER ;;
CREATE PROCEDURE playerCapturedPoint(_steamId varchar(32), _playerName varchar(64), _playerRole tinyint, _map varchar(64), _areaId tinyint, _areaName varchar(64))
BEGIN
  DECLARE _pointId int;
  DECLARE _playerId int;

  INSERT INTO players (steamId, name) VALUES (_steamId, _playerName)
  ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), name = _playerName, lastCap = CURRENT_TIMESTAMP;
  SELECT LAST_INSERT_ID() INTO _playerId;

  IF (_playerRole = 3) THEN
    INSERT INTO points (map, areaId, areaName, capsSoldier) VALUES (_map, _areaId, _areaName, 1)
    ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), capsSoldier = capsSoldier + 1, areaName = _areaName;  -- TODO remove `, areaName = _areaName`
    SELECT LAST_INSERT_ID() INTO _pointId;

    INSERT INTO pointCaps (playerId, playerRole, pointId) VALUES (_playerId, 'soldier', _pointId)
    ON DUPLICATE KEY UPDATE capsCount = capsCount + 1, lastCap = CURRENT_TIMESTAMP;
  END IF;

  IF (_playerRole = 4) THEN
    INSERT INTO points (map, areaId, areaName, capsDemoman) VALUES (_map, _areaId, _areaName, 1)
    ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), capsDemoman = capsDemoman + 1, areaName = _areaName;  -- TODO remove `, areaName = _areaName`
    SELECT LAST_INSERT_ID() INTO _pointId;

    INSERT INTO pointCaps (playerId, playerRole, pointId) VALUES (_playerId, 'demoman', _pointId)
    ON DUPLICATE KEY UPDATE capsCount = capsCount + 1, lastCap = CURRENT_TIMESTAMP;
  END IF;
END
;;
DELIMITER ;

-- SAFE TO DELETE --
DELIMITER ;;
CREATE PROCEDURE _playerCapturedPointMigrate(_steamId varchar(32), _playerName varchar(64), _playerRole tinyint, _map varchar(64), _areaId tinyint, _areaName varchar(64), _timestamp int)
BEGIN
  DECLARE _pointId int;
  DECLARE _playerId int;

  INSERT INTO players (steamId, name, lastCap) VALUES (_steamId, _playerName, _timestamp)
  ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), name = _playerName, lastCap = _timestamp;
  SELECT LAST_INSERT_ID() INTO _playerId;

  IF (_playerRole = 3) THEN
    INSERT INTO points (map, areaId, areaName, capsSoldier) VALUES (_map, _areaId, _areaName, 1)
    ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), capsSoldier = capsSoldier + 1;
    SELECT LAST_INSERT_ID() INTO _pointId;

    INSERT INTO pointCaps (playerId, playerRole, pointId, lastCap) VALUES (_playerId, 'soldier', _pointId, _timestamp)
    ON DUPLICATE KEY UPDATE capsCount = capsCount + 1, lastCap = _timestamp;
  END IF;

  IF (_playerRole = 4) THEN
    INSERT INTO points (map, areaId, areaName, capsDemoman) VALUES (_map, _areaId, _areaName, 1)
    ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), capsDemoman = capsDemoman + 1;
    SELECT LAST_INSERT_ID() INTO _pointId;

    INSERT INTO pointCaps (playerId, playerRole, pointId, lastCap) VALUES (_playerId, 'demoman', _pointId, _timestamp)
    ON DUPLICATE KEY UPDATE capsCount = capsCount + 1, lastCap = _timestamp;
  END IF;
END
;;
DELIMITER ;
