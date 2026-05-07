class_name CombatConstants
extends RefCounted

const RANDOM_SIZE: int = 119
const MAX_BEAMS: int = 10
const MAX_TORPS: int = 10
const MAX_FIGHTERS: int = 19

const SHIP_TO_SHIP: int = 0
const SHIP_TO_PLANET: int = 1

const FIGHTER_IDLE: int = 0
const FIGHTER_ATTACKS: int = 1
const FIGHTER_RETURNS: int = 2

const VCRS_NONE: int = 0
const VCRS_LEFT_DESTROYED: int = 1
const VCRS_RIGHT_DESTROYED: int = 2
const VCRS_LEFT_CAPTURED: int = 4
const VCRS_RIGHT_CAPTURED: int = 8
const VCRS_TIMEOUT: int = 16
const VCRS_STALEMATE: int = 32
const VCRS_INVALID: int = -1
