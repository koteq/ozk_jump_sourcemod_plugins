CREATE TABLE `maps` (
  name varchar(64) NOT NULL,
  team enum('red','blu','both') NOT NULL,
  role enum('soldier','demoman') NOT NULL,
  difficulty enum('v.easy','easy','medium','multistage','hard','expert','insane') NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

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
  capsCount int(10) unsigned NOT NULL DEFAULT '1',
  lastCap timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY idx_pointCaps_unique (playerId,playerRole,pointId),
  KEY idx_pointCaps_role_lastCap (playerRole,lastCap)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE points (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  map varchar(64) NOT NULL,
  areaId tinyint(4) NOT NULL,
  areaName varchar(64) NOT NULL,
  score float unsigned NOT NULL DEFAULT '0',
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

DELIMITER ;;
CREATE FUNCTION steam32ToCommunityId(_steamId VARCHAR(64)) RETURNS bigint(64)
BEGIN
	DECLARE _authServer INT;
	DECLARE _authId INT;

	SET _authServer = CAST(SUBSTR(_steamId, 9, 1) AS UNSIGNED INTEGER);
	SET _authId = CAST(SUBSTR(_steamId, 11) AS UNSIGNED INTEGER);
	RETURN 76561197960265728 + (_authId * 2) + _authServer;
END
;;
DELIMITER ;
