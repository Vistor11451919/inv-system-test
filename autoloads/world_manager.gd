extends Node

## WorldManager — 实体注册/查找（使用 weakref，与主项目 EnemyBase 兼容）

const PLAYER_ID: int = 1

var _entities: Dictionary = {}
var _next_id: int = 100

func register_entity(node: Node) -> int:
	var eid = _next_id
	_next_id += 1
	_entities[eid] = weakref(node)
	return eid

func register_player(entity: Node) -> int:
	_entities[PLAYER_ID] = weakref(entity)
	return PLAYER_ID

func unregister_entity(entity_id: int):
	_entities.erase(entity_id)

func get_entity(entity_id: int):
	if not _entities.has(entity_id):
		return null
	return _entities[entity_id].get_ref()
