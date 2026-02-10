extends Node
class_name AudioManager

# It isn't clear why, but I did not have to do anything to the loops to get them to loop properly, 
# or do anything to the SFXs to get it to not loop, so I guess the looping behavior is just determined by something in the audio file itself?
const FOREST_LOOP_1: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/forestLoop1.wav")
const FOREST_LOOP_2: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/forestLoop2.wav")
const MYSTERY_LOOP_1: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/mysteryAmbience.wav")
const HEAVY_RAIN_AMBIENCE: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/heavyRain.wav")
const LIGHT_RAIN_AMBIENCE: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/lightRain.wav")
const FLOOD_AMBIENCE: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/floodAmbience.wav")
const CAVE_AMBIENCE: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/caveAmbience.wav")

const TURTLE_SPLASH_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/turtleSplash.wav")
const LIZARD_RUN_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/lizardRun.wav")
const MAMMAL_SCURRY_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/mammalScurry.wav")
const GATOR_GROWL_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/gatorGrowl.wav")
const DINO_FOOTSTEP_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/dinoFootstep.wav")
const CAVE_ENTRANCE_NOISE_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/caveEntranceNoise.wav")
const TRI_CHEWING_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/triChewing.wav")
const DISTANT_THUNDER_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/distantThunder.wav")
const QUIET_DINO_SNARL_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/quietDinoSnarl.wav")
const CLOSE_THUNDER_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/closeThunder.wav")
const TRI_GORING_TYRAN_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/triGoringTyran.wav")
const TYRAN_RENDING_FLESH_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/tyranRendingFlesh.wav")
const TYRAN_EATING_OUT_OF_CAVE_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/tyranEatingOutOfCave.wav")
const TYRAN_EATING_IN_CAVE_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/tyranEatingInCave.wav")
const TYRAN_FALL_OUT_OF_CAVE_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/tyranFallOutOfCave.wav")
const TYRAN_FALL_IN_CAVE_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/tyranFallInCave.wav")
const TYRAN_DROWN_ROAR_SFX: AudioStreamWAV = preload("res://interactive narrative/assets/sounds/tyranDrownRoar.wav")

# Defines a map between a string and a sound effect,
# so that the dialogue script can just call play_sound("sfx_name"),
# or switch_background_music("bgm_name"), and this script will know which sound to play.
var sound_effects_map = {
	"turtle_splash": TURTLE_SPLASH_SFX,
	"lizard_run": LIZARD_RUN_SFX,
	"mammal_scurry": MAMMAL_SCURRY_SFX,
	"gator_growl": GATOR_GROWL_SFX,
	"dino_footstep": DINO_FOOTSTEP_SFX,
	"cave_entrance_noise": CAVE_ENTRANCE_NOISE_SFX,
	"tri_chewing": TRI_CHEWING_SFX,
	"distant_thunder": DISTANT_THUNDER_SFX,
	"quiet_dino_snarl": QUIET_DINO_SNARL_SFX,
	"close_thunder": CLOSE_THUNDER_SFX,
	"tri_goring_tyran": TRI_GORING_TYRAN_SFX,
	"tyran_rending_flesh": TYRAN_RENDING_FLESH_SFX,
	"tyran_eating_out_of_cave": TYRAN_EATING_OUT_OF_CAVE_SFX,
	"tyran_eating_in_cave": TYRAN_EATING_IN_CAVE_SFX,
	"tyran_fall_out_of_cave": TYRAN_FALL_OUT_OF_CAVE_SFX,
	"tyran_fall_in_cave": TYRAN_FALL_IN_CAVE_SFX,
	"tyran_drown_roar": TYRAN_DROWN_ROAR_SFX
}

var background_music_map = {
	"forest_loop_1": FOREST_LOOP_1,
	"forest_loop_2": FOREST_LOOP_2,
	"mystery_loop_1": MYSTERY_LOOP_1,
	"heavy_rain": HEAVY_RAIN_AMBIENCE,
	"light_rain": LIGHT_RAIN_AMBIENCE,
	"flood_ambience": FLOOD_AMBIENCE,
	"cave_ambience": CAVE_AMBIENCE
}

# Two AudioStreamPlayers are used for background music, so that we can crossfade between them.
# When switching music, the new music will start fading in on the player that isn't currently playing, 
# while the old music fades out on the player that is currently playing. Once the fade is complete, 
# the old music will be stopped, and the new music will be fully faded in and become the "current" player.
@onready var bgm_player1: AudioStreamPlayer = $BgmPlayer1
@onready var bgm_player2: AudioStreamPlayer = $BgmPlayer2

# This will point to either bgm_player1 or bgm_player2, or nothing if no music is currently playing. 
var current_bgm_player: AudioStreamPlayer = null

@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

# Key of the currently playing background music.
# This is the key into the background_music_map.
var current_bgm_key := ""

# Current volume of the background music, measured in percent of the max volume, on a linear scale.
# In the steady state, music will be playing at this volume (I think?).
var bgm_max_volume_linear := 1.0

# Used to determine silence volume for fading in from silence/out to silence.
var bgm_silence_linear := 0.00

## Switches the background music to the given key, fading out the old music and fading in the new music over the given fade time.
## If the key is an empty string, just fades out the current music without fading in new music.
## If the key is the same as the currently playing music, does nothing.
## [br]
## **param** key The key of the background music to switch to.
## [br] 
## **param** fade_time The time in seconds to fade out the old music and fade in the new music.
func switch_background_music(key: String, fade_time: float = 4.0) -> void:
	# Basic validation of parameters.

	if key != "" and not background_music_map.has(key):
		print("Unknown background music key: %s" % key)
		return

	# No need to do any work if the requested music is already playing.
	if key == current_bgm_key and current_bgm_player.playing:
		return


	# I learned how to tween from https://docs.godotengine.org/en/stable/classes/class_tween.html
	# Basically, the process seems to be:
	# 1. Create a tween with get_tree().create_tween()
	# 2. figure out some property you want to tween (like volume_db)
	# 3. call tween_property() on the tween, passing in the object, property name, target value, and duration
	# 4. call tween_property() some more if you want to do more fancy stuff
	# 5. call tween_callback() to do something when the tween is done, like freeing an object or starting new music
	var tween = get_tree().create_tween()

	# If current_bgm_player is null, that means no music is currently playing, so we can just start the new music without fading out.
	# For simplicity, we shall set it to bgm_player1 in this case, though this is arbitrary and we could just as well set it to bgm_player2.
	# Alternatively, if current_bgm_player is not null, we want to fade out the current music on that player, and fade in the new music on the other player.
	# We then want to update current_bgm_player to point to the player that is playing the new music.
	if current_bgm_player == null:
		# No music is currently playing, so we can just start the new music without fading out.
		current_bgm_player = bgm_player1

		# https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html
		# "The AudioStreamPlayer node plays an audio stream non-positionally. It is ideal for user interfaces, menus, or background music.
		# To use this node, stream needs to be set to a valid AudioStream resource."
		current_bgm_player.stream = background_music_map[key]

		# We set the volume to silence before starting to play, 
		# so that it can fade in from silence rather than abruptly starting at full volume.
		current_bgm_player.volume_linear = bgm_silence_linear

		# "void play(from_position: float = 0.0)" will start playing the audio stream from the given position (in seconds).
		current_bgm_player.play()

		current_bgm_key = key

		# Fade in from silence to the target volume.
		tween.tween_property(current_bgm_player, "volume_linear", bgm_max_volume_linear, fade_time)
		
		# We're done, so we can return early.
		return 

	# We keep track of the old player so that we can stop it after fading out, 
	# then we update current_bgm_player to point to the new player that will be fading in the new music.
	var old_bgm_player = current_bgm_player
	if current_bgm_player == bgm_player1:
		current_bgm_player = bgm_player2
	else:
		current_bgm_player = bgm_player1

	# Start fading out the old music to silence.
	var old_music_tween = get_tree().create_tween()
	old_music_tween.tween_property(old_bgm_player, "volume_linear", bgm_silence_linear, fade_time)

	# After fading out, we stop the old music completely. 
	# If the key is an empty string, that means we just want to fade out the current music without fading in new music, 
	# so in that case we stop the old music and set current_bgm_player to null to indicate that no music is currently playing.
	# https://docs.godotengine.org/en/stable/classes/class_callable.html
	# I learned that I can make a callable from a func like this: func(): ... 
	# and then pass that to tween_callback.
	old_music_tween.tween_callback(func():
		if key == "":
			old_bgm_player.stop()
			old_bgm_player.stream = null
			current_bgm_player = null
			current_bgm_key = ""
			return
	)

	# If we're also fading in new music, we can start that tween at the same time as fading out the old music.
	if key != "":
		# Start playing the new music on the new player, 
		# but with its volume set to silence so that it fades in from silence rather than abruptly starting at full volume.
		current_bgm_player.stream = background_music_map[key]
		current_bgm_player.volume_linear = bgm_silence_linear
		current_bgm_player.play()
		current_bgm_key = key

		# Start fading in the new music to the target volume.
		tween.tween_property(current_bgm_player, "volume_linear", bgm_max_volume_linear, fade_time * 0.5)

		# We're done.

## Plays the sound effect associated with the given key.
## If the key is not found in the sound_effects_map, does nothing.
## [br]
## **param** key The key of the sound effect to play.
func play_sound_effect(key: String) -> void:

	# Basic validation of parameters.
	if not sound_effects_map.has(key):
		print("Unknown sound effect key: %s" % key)
		return
	
	sfx_player.stream = sound_effects_map[key]
	sfx_player.play()
