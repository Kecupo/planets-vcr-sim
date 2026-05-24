class_name CombatRngThost
extends RefCounted

const RANDOM_SIZE: int = 119
const MT_N: int = 624
const MT_M: int = 397
const MT_MATRIX_A: int = 0x9908b0df
const MT_UPPER_MASK: int = 0x80000000
const MT_LOWER_MASK: int = 0x7fffffff
const UINT32_MASK: int = 0xffffffff

const RAND_1_20: PackedInt32Array = ([
	9,8,11,8,5,5,9,10,15,2,10,4,14,18,1,14,15,17,2,4,
	10,13,16,17,11,10,14,7,2,8,13,13,18,6,13,12,6,12,6,14,
	4,1,20,16,16,2,8,10,18,4,20,16,17,15,6,19,16,14,2,15,
	11,6,9,17,15,4,3,12,16,19,12,18,11,13,13,8,3,2,15,5,
	12,6,10,6,9,16,20,19,18,17,11,1,4,12,7,13,15,5,7,12,
	3,3,7,14,10,18,13,3,16,14,4,13,9,14,2,9,7,4,15
])

const RAND_1_100: PackedInt32Array = ([
	42,36,54,39,23,21,41,45,73,5,47,14,71,89,2,70,76,83,5,16,
	50,64,78,87,53,47,66,33,5,37,63,61,88,29,62,58,26,61,30,67,
	16,2,98,78,81,7,37,46,88,15,99,77,82,75,25,96,79,69,5,71,
	54,25,43,87,75,17,13,58,78,96,57,87,52,63,64,36,14,5,73,23,
	58,29,48,27,43,77,99,95,88,84,55,2,15,57,33,61,76,22,31,61,
	11,13,31,70,45,92,61,11,80,71,14,62,44,70,4,40,32,18,74
])

const RAND_1_17: PackedInt32Array = ([
	8,7,10,7,5,4,7,8,13,2,8,3,12,15,1,12,13,14,2,3,
	9,11,13,15,9,8,12,6,2,7,11,11,15,5,11,10,5,11,6,12,
	3,1,17,14,14,2,7,8,15,3,17,13,14,13,5,16,14,12,2,12,
	10,5,8,15,13,4,3,10,13,16,10,15,9,11,11,7,3,2,13,5,
	10,5,9,5,8,13,17,16,15,14,10,1,3,10,6,11,13,4,6,11,
	3,3,6,12,8,16,11,3,14,12,3,11,8,12,2,7,6,4,13
])

var _seed: int = 1
var _use_twister: bool = false
var _mt: Array[int] = []
var _mt_index: int = MT_N + 1

func set_seed(p_seed: int) -> void:
	if p_seed < 0:
		_use_twister = true
		_init_twister(abs(p_seed))
		_seed = p_seed
		return

	_use_twister = false
	var s: int = p_seed % RANDOM_SIZE
	if s < 0:
		s += RANDOM_SIZE
	_seed = s

func get_seed() -> int:
	return _seed

func _advance_and_get_index() -> int:
	_seed = 1 if _seed >= RANDOM_SIZE else _seed + 1
	return _seed - 1

func random_1_20() -> int:
	if _use_twister:
		return RAND_1_20[_twister_int(RANDOM_SIZE)]
	return RAND_1_20[_advance_and_get_index()]

func random_1_100() -> int:
	if _use_twister:
		return RAND_1_100[_twister_int(RANDOM_SIZE)]
	return RAND_1_100[_advance_and_get_index()]

func random_1_17() -> int:
	if _use_twister:
		return RAND_1_17[_twister_int(RANDOM_SIZE)]
	return RAND_1_17[_advance_and_get_index()]

func advance_beam_fighter_skip(beam_count: int) -> void:
	if _use_twister:
		return
	_seed = (_seed + beam_count) % RANDOM_SIZE


func _init_twister(seed: int) -> void:
	_mt.resize(MT_N)
	_mt[0] = _uint32(seed)
	for i: int in range(1, MT_N):
		var prev: int = _mt[i - 1]
		_mt[i] = _uint32(1812433253 * (prev ^ (prev >> 30)) + i)
	_mt_index = MT_N


func _twister_int(limit: int) -> int:
	var rejection_limit: int = UINT32_MASK - (UINT32_MASK % limit)
	var value: int = _twister_int32()
	while value >= rejection_limit:
		value = _twister_int32()
	return value % limit


func _twister_int32() -> int:
	if _mt_index >= MT_N:
		_generate_twister_words()

	var y: int = _mt[_mt_index]
	_mt_index += 1

	y = _uint32(y ^ (y >> 11))
	y = _uint32(y ^ ((y << 7) & 0x9d2c5680))
	y = _uint32(y ^ ((y << 15) & 0xefc60000))
	y = _uint32(y ^ (y >> 18))
	return y


func _generate_twister_words() -> void:
	if _mt.is_empty():
		_init_twister(5489)

	for kk: int in range(0, MT_N - MT_M):
		var y: int = (_mt[kk] & MT_UPPER_MASK) | (_mt[kk + 1] & MT_LOWER_MASK)
		_mt[kk] = _uint32(_mt[kk + MT_M] ^ (y >> 1) ^ _twister_mag(y))

	for kk: int in range(MT_N - MT_M, MT_N - 1):
		var y: int = (_mt[kk] & MT_UPPER_MASK) | (_mt[kk + 1] & MT_LOWER_MASK)
		_mt[kk] = _uint32(_mt[kk + (MT_M - MT_N)] ^ (y >> 1) ^ _twister_mag(y))

	var y: int = (_mt[MT_N - 1] & MT_UPPER_MASK) | (_mt[0] & MT_LOWER_MASK)
	_mt[MT_N - 1] = _uint32(_mt[MT_M - 1] ^ (y >> 1) ^ _twister_mag(y))
	_mt_index = 0


func _twister_mag(value: int) -> int:
	return MT_MATRIX_A if (value & 1) != 0 else 0


func _uint32(value: int) -> int:
	return value & UINT32_MASK
