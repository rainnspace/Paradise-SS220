/**
  * # Hallucination - Terror Infestation
  *
  * Creates spider webs and a terror spider near a random vent around the target.
  */
/obj/effect/hallucination/terror_infestation
	duration = 30 SECONDS

/obj/effect/hallucination/terror_infestation/Initialize(mapload, mob/living/carbon/target)
	. = ..()

	// Find a vent around us
	var/list/vents = list()
	for(var/obj/machinery/atmospherics/unary/vent_pump/vent in range(world.view, target))
		vents += vent
	if(!length(vents))
		return

	// Spawn webs around a random vent
	var/obj/vent = pick(vents)
	for(var/t in RANGE_TURFS(1, vent))
		var/turf/T = t
		if(!isfloorturf(T))
			continue
		new /obj/effect/hallucination/tripper/spider_web(T, target)

	new /obj/effect/hallucination/chaser/attacker/terror_spider(get_turf(vent), target)

/obj/effect/hallucination/chaser/attacker/terror_spider
	hallucination_icon = 'icons/mob/terrorspider.dmi'
	hallucination_icon_state = "terror_green"
	duration = 30 SECONDS
	damage = 25

/obj/effect/hallucination/chaser/attacker/terror_spider/Initialize(mapload, mob/living/carbon/target)
	. = ..()
	name = "Green Terror spider ([rand(100, 999)])"

/obj/effect/hallucination/chaser/attacker/terror_spider/attack_effects()
	do_attack_animation(target, ATTACK_EFFECT_BITE)
	target.playsound_local(get_turf(src), 'sound/weapons/bite.ogg', 50, TRUE)
	to_chat(target, "<span class='userdanger'>[name] bites you!</span>")

/obj/effect/hallucination/chaser/attacker/terror_spider/on_knockdown()
	target.visible_message("<span class='warning'>[target] recoils as if hit by something, before suddenly collapsing!</span>",
						"<span class='userdanger'>[name] bites you!</span>")

/**
  * # Hallucination - Spider Web
  *
  * A fake spider web that trips the target if crossed.
  */
/obj/effect/hallucination/tripper/spider_web
	name = "spider web"
	desc = "It's stringy and sticky."
	hallucination_icon = 'icons/effects/effects.dmi'
	hallucination_icon_state = "stickyweb1"
	hallucination_override = TRUE
	hallucination_layer = OBJ_LAYER
	trip_chance = 80

/obj/effect/hallucination/tripper/spider_web/Initialize(mapload, mob/living/carbon/target)
	if(prob(50))
		hallucination_icon_state = "stickyweb2"
	. = ..()

/obj/effect/hallucination/tripper/spider_web/on_crossed()
	target.visible_message("<span class='warning'>[target] trips over nothing.</span>",
						"<span class='userdanger'>You get stuck in [src]!</span>")

/obj/effect/hallucination/tripper/spider_web/attackby__legacy__attackchain(obj/item/I, mob/user, params)
	if(user != target)
		return

	step_towards(target, get_turf(src))
	target.Weaken(4 SECONDS)
	target.visible_message("<span class='warning'>[target] flails [target.p_their()] [I.name] as if striking something, only to trip!</span>",
						"<span class='userdanger'>[src] vanishes as you strike it with [I], causing you to stumble forward!</span>")
	qdel(src)

/**
  * # Hallucination - Abduction
  *
  * Sends an abductor agent after the target. On knockdown, spawns an abductor scientist next to the target. Nothing else happens.
  */
/obj/effect/hallucination/abduction
	duration = 45 SECONDS
	/// The abductor agent hallucination.
	var/obj/effect/hallucination/chaser/attacker/abductor/agent = null
	/// The abductor scientist image handle.
	var/image/scientist = null

/obj/effect/hallucination/abduction/Initialize(mapload, mob/living/carbon/target)
	. = ..()

	var/list/locs = list()
	for(var/turf/T in oview(world.view, target))
		if(!is_blocked_turf(T))
			locs += T
	if(!length(locs))
		qdel(src)
		return

	// Spawn agent
	var/turf/T = pick(locs)
	agent = new(T, target)
	agent.owning_hallucination = src

	// Teleport effect
	var/image/teleport_end = image('icons/mob/mob.dmi', T, "uncloak", layer = ABOVE_MOB_LAYER)
	teleport_end.plane = GAME_PLANE
	add_icon(teleport_end)
	clear_icon_in(teleport_end, 0.9 SECONDS)

/obj/effect/hallucination/abduction/Destroy()
	QDEL_NULL(agent)
	QDEL_NULL(scientist)
	return ..()

/**
  * Called when the fake abductor scientist should spawn.
  */
/obj/effect/hallucination/abduction/proc/spawn_scientist()
	// Find a spot for the scientist to spawn
	var/list/locs = list()
	for(var/turf/T in orange(1, target))
		if(!is_blocked_turf(T))
			locs += T
	locs -= get_turf(agent)
	if(!length(locs))
		qdel(src)
		return

	QDEL_IN(src, 10 SECONDS)

	var/turf/T = pick(locs)
	// Spawn the scientist in
	var/image/teleport = image('icons/obj/abductor.dmi', T, "teleport", layer = ABOVE_MOB_LAYER)
	teleport.plane = GAME_PLANE
	add_icon(teleport)
	clear_icon_in(teleport, 4 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(do_spawn_scientist), T), 4 SECONDS)
	playsound(T, "sparks", 100, TRUE)

/**
  * Timer called to actually spawn the scientist.
  *
  * Arguments:
  * * T - Where to spawn the scientist.
  */
/obj/effect/hallucination/abduction/proc/do_spawn_scientist(turf/T)
	if(QDELETED(target))
		qdel(src)
		return
	else if(scientist)
		return

	var/image/teleport_end = image('icons/mob/mob.dmi', T, "uncloak", layer = ABOVE_MOB_LAYER)
	teleport_end.plane = GAME_PLANE
	add_icon(teleport_end)
	clear_icon_in(teleport_end, 0.9 SECONDS)

	scientist = image('icons/mob/simple_human.dmi', T, "abductor_scientist", layer = MOB_LAYER)
	scientist.plane = GAME_PLANE
	scientist.dir = get_dir(T, target)
	add_icon(scientist)

/obj/effect/hallucination/chaser/attacker/abductor
	hallucination_icon = 'icons/mob/simple_human.dmi'
	hallucination_icon_state = "abductor_agent"
	duration = 45 SECONDS
	damage = 100
	/// The hallucination that spawned us.
	var/obj/effect/hallucination/abduction/owning_hallucination = null

/obj/effect/hallucination/chaser/attacker/abductor/Initialize(mapload, mob/living/carbon/target)
	. = ..()
	name = "Unknown"

/obj/effect/hallucination/chaser/attacker/abductor/attack_effects()
	do_attack_animation(target)
	target.playsound_local(get_turf(src), 'sound/weapons/egloves.ogg', 50, TRUE)

/obj/effect/hallucination/chaser/attacker/abductor/on_knockdown()
	target.visible_message("<span class='warning'>[target] recoils as if hit by something, before suddenly collapsing!</span>",
						"<span class='userdanger'>[name] has stunned you with the advanced baton!</span>")
	if(!QDELETED(owning_hallucination))
		owning_hallucination.spawn_scientist()
	else
		qdel(src)

/**
  * # Hallucination - Loose Energy Ball
  *
  * A progressive hallucination that begins with intermittent explosions, before displaying an energy ball that shocks the target.
  */
/obj/effect/hallucination/loose_energy_ball
	duration = 30 SECONDS
	/// Length of phase 1 in deciseconds.
	var/length_phase_1 = 10 SECONDS
	/// Length of phase 2 in deciseconds.
	var/length_phase_2 = 10 SECONDS
	/// Length of phase 3 in deciseconds.
	var/length_phase_3 = 6 SECONDS

/obj/effect/hallucination/loose_energy_ball/Initialize(mapload)
	. = ..()
	phase_1()
	addtimer(CALLBACK(src, PROC_REF(phase_2)), length_phase_1)
	addtimer(CALLBACK(src, PROC_REF(phase_3)), length_phase_1 + length_phase_2)

/**
  * First phase of the hallucination: intermittent, far-away explosion sounds.
  */
/obj/effect/hallucination/loose_energy_ball/proc/phase_1()
	for(var/i in 0 to (length_phase_1 / 20) - 1)
		play_sound_in(i * 2 SECONDS, null, 'sound/effects/explosionfar.ogg', min(50 + i * 5, 100))

/**
  * Second phase of the hallucination: closer explosions and zap sounds from a random direction.
  */
/obj/effect/hallucination/loose_energy_ball/proc/phase_2()
	var/turf/source = get_step_rand(get_turf(target))
	for(var/i in 0 to (length_phase_2 / 20) - 1)
		if(prob(33))
			play_sound_in(i * 2 SECONDS, source, pick('sound/effects/explosion1.ogg', 'sound/effects/explosion2.ogg'), min(5 + i * 3, 100))
		play_sound_in(i * 2 SECONDS, source, 'sound/magic/lightningbolt.ogg', min(5 + i * 3, 100))

/**
  * Third and final phase of the hallucination: an energy ball that approaches the target before shocking it.
  */
/obj/effect/hallucination/loose_energy_ball/proc/phase_3()
	// Create the image
	var/image/ball = image('icons/obj/tesla_engine/energy_ball.dmi', src, "energy_ball")
	ball.layer = MASSIVE_OBJ_LAYER
	ball.plane = GAME_PLANE
	add_icon(ball)

	var/steps = (length_phase_3 / 20) - 1
	for(var/i in 0 to steps)
		addtimer(CALLBACK(src, PROC_REF(phase_3_inner), ball, steps - i, i), i * 2 SECONDS)

/**
  * Called during phase 3 to approach the energy ball towards the target.
  *
  * Arguments:
  * * ball - The energy ball image.
  * * distance - The remaining distance.
  * * step - The current step.
  */
/obj/effect/hallucination/loose_energy_ball/proc/phase_3_inner(image/ball, distance, step)
	if(QDELETED(ball) || QDELETED(target))
		return

	var/turf/T = get_turf(target)
	var/list/turfs = RANGE_TURFS(distance + 1, T) // expensive?
	var/turf/dest = pick(turfs) || T // uh oh

	ball.loc = dest
	target.playsound_local(dest, 'sound/magic/lightningbolt.ogg', 15 + step * 10)
	target.playsound_local(dest, 'sound/magic/lightningshock.ogg', 15 + step * 10)

	if(distance == 0)
		target.electrocute_act(100, src, flags = SHOCK_ILLUSION)

/**
  * # Hallucination - Assault
  *
  * An imaginary attacker spawns close to the target and attacks them to stamcrit.
  */
/obj/effect/hallucination/assault
	duration = 30 SECONDS
	/// The attacker hallucination.
	var/obj/effect/hallucination/chaser/attacker/assaulter/fake_attacker = null

/obj/effect/hallucination/assault/Initialize(mapload, mob/living/carbon/target)
	. = ..()

	var/list/locs = list()
	for(var/turf/T in oview(world.view / 2, target))
		if(!is_blocked_turf(T))
			locs += T
	if(!length(locs))
		qdel(src)
		return

	// Spawn attacker
	var/turf/T = pick(locs)
	fake_attacker = new(T, target)

/obj/effect/hallucination/chaser/attacker/assaulter
	duration = 30 SECONDS
	damage = 40
	/// The attack verb to display.
	var/attack_verb = "punches"
	/// The attack sound to play. Can be a file or text (passed to [/proc/get_sfx]).
	var/attack_sound = "punch"

/obj/effect/hallucination/chaser/attacker/assaulter/Initialize(mapload, mob/living/carbon/target)
	var/new_name
	// 80% chance to use a simple human sprite
	if(prob(80))
		new_name = "Unknown"
		hallucination_icon = 'icons/mob/simple_human.dmi'
		hallucination_icon_state = pick("arctic_skeleton", "templar", "skeleton", "sovietmelee", "piratemelee", "plasma_miner_tool", "cat_butcher", "syndicate_space_sword", "syndicate_stormtrooper_sword", "zombie", "scary_clown")

		// Adjust the attack verb and sound depending on the "mob"
		switch(hallucination_icon_state)
			if("arctic_skeleton", "templar", "sovietmelee", "plasma_miner_tool")
				attack_verb = "slashed"
				attack_sound = 'sound/weapons/bladeslice.ogg'
			if("cat_butcher")
				attack_verb = "sawed"
				attack_sound = 'sound/weapons/circsawhit.ogg'
			if("piratemelee", "syndicate_space_sword", "syndicate_stormtrooper_sword")
				attack_verb = "slashed"
				attack_sound = 'sound/weapons/blade1.ogg'

	// If nothing else we'll stay a monke
	. = ..()
	name = new_name || name

/obj/effect/hallucination/chaser/attacker/assaulter/attack_effects()
	do_attack_animation(target)
	target.playsound_local(get_turf(src), istext(attack_sound) ? get_sfx(attack_sound) : attack_sound, 25, TRUE)
	to_chat(target, "<span class='userdanger'>[name] has [attack_verb] [target]!</span>")

/obj/effect/hallucination/chaser/attacker/assaulter/on_knockdown()
	target.visible_message("<span class='warning'>[target] recoils as if hit by something, before suddenly collapsing!</span>",
						"<span class='userdanger'>[name] has [attack_verb] [target]!</span>")
	QDEL_IN(src, 3 SECONDS)

/obj/effect/hallucination/blob
	duration = 30 SECONDS
	/// The blob zombie hallucination.
	var/obj/effect/hallucination/chaser/attacker/blob_zombie/zombie
	/// The self delusion blob zombie hallucination, triggers on knockdown.
	var/obj/effect/hallucination/blob_zombify/player_zombie
	/// List of turfs that need expanding from.
	var/list/turf/expand_queue = list()
	/// Associative list of turfs that have already been processed.
	var/list/turf/processed = list()
	/// The image for the chaser zombie's blob head
	var/image/chaser_blob_head
	/// The image for the player zombie's blob head
	var/image/target_blob_head
	/// The delay at which the blob expands in deciseconds. Shouldn't be too low to prevent lag.
	var/expand_delay
	/// The amount of time in deciseconds the hallucination should continue after final expansion.
	var/conclude_delay = 2 SECONDS
	/// Expand timer handle.
	var/expand_timer

/obj/effect/hallucination/blob/Initialize(mapload, mob/living/carbon/target, expansions = 4)
	. = ..()
	expand_delay = (duration - conclude_delay) / max(1, expansions)
	var/list/locs = list()
	for(var/turf/T in oview(world.view / 2, target))
		var/light_amount = T.get_lumcount()
		if(!is_blocked_turf(T) && light_amount <= 0.5)
			locs += T
	if(!length(locs))
		return INITIALIZE_HINT_QDEL
	var/turf/T = get_turf(pick(locs))
	color = pick(COLOR_BLACK, 
		COLOR_RIPPING_TENDRILS, 
		COLOR_BOILING_OIL, 
		COLOR_ENVENOMED_FILAMENTS, 
		COLOR_LEXORIN_JELLY,
		COLOR_KINETIC_GELATIN, 
		COLOR_CRYOGENIC_LIQUID, 
		COLOR_SORIUM, 
		COLOR_TESLIUM_PASTE)
	create_blob(T, core = TRUE)
	target.playsound_local(T, 'sound/effects/splat.ogg', 50, 1)
	create_zombie(T)
	expand_queue += T
	processed[T] = TRUE
	expand_timer = addtimer(CALLBACK(src, PROC_REF(expand)), expand_delay, TIMER_LOOP | TIMER_STOPPABLE)

/obj/effect/hallucination/blob/Destroy()
	deltimer(expand_timer)
	expand_queue.Cut()
	processed.Cut()
	QDEL_NULL(zombie)
	QDEL_NULL(player_zombie)
	if(!QDELETED(target))
		target.client?.images -= chaser_blob_head
		target.client?.images -= target_blob_head
	chaser_blob_head = null
	target_blob_head = null
	return ..()

/**
  * Called regularly in a timer to process the blob expanding.
  */
/obj/effect/hallucination/blob/proc/expand()
	// Brace for potentially expensive proc
	for(var/turf/source_turf as anything in expand_queue)
		expand_queue -= source_turf
		//Expand to each dir
		for(var/direction in GLOB.cardinal)
			var/turf/target_turf = get_step(source_turf, direction)
			if(processed[target_turf] || !source_turf.CanAtmosPass(direction) || !target_turf.CanAtmosPass(turn(direction, 180)))
				continue
			create_blob(target_turf)
			expand_queue += target_turf
			processed[target_turf] = TRUE

/**
  * Creates a fake blob overlay on the given turf.
  *
  * Arguments:
  * * T - The turf to create a fake blob overlay on.
  */
/obj/effect/hallucination/blob/proc/create_blob(turf/T, core = FALSE)
	var/blob_icon_state = "blob"
	if(core)
		blob_icon_state = "blob_core"
	var/image/I = image('icons/mob/blob.dmi', T, blob_icon_state, layer = FLY_LAYER)
	I.plane = GAME_PLANE
	I.color = color
	add_icon(I)

/obj/effect/hallucination/blob/proc/create_zombie(turf/T)
	zombie = new(T, target, src)

/obj/effect/hallucination/blob/proc/zombify(turf/T)
	player_zombie = new(T, target, src)

/obj/effect/hallucination/chaser/attacker/blob_zombie
	name = "blob zombie"
	hallucination_icon = 'icons/mob/human.dmi'
	hallucination_icon_state = "zombie2_s"
	duration = 45 SECONDS
	damage = 25
	/// The hallucination that spawned us.
	var/obj/effect/hallucination/blob/owning_hallucination = null
	/// Whether or not the target has been zombified already.
	var/has_zombified = FALSE

/obj/effect/hallucination/chaser/attacker/blob_zombie/Initialize(mapload, mob/living/carbon/target, obj/effect/hallucination/blob/blob)
	. = ..()
	name = "blob zombie"
	var/image/I = image('icons/mob/blob.dmi', src, "blob_head")
	I.color = blob.color
	target.client.images += I
	owning_hallucination = blob
	blob.chaser_blob_head = I

/obj/effect/hallucination/chaser/attacker/blob_zombie/attack_effects()
	do_attack_animation(target)
	target.playsound_local(get_turf(src), 'sound/weapons/genhit1.ogg', 50, TRUE)
	to_chat(target, "<span class='userdanger'>[name] has hit [target]!</span>")

/obj/effect/hallucination/chaser/attacker/blob_zombie/on_knockdown()
	if(!QDELETED(owning_hallucination))
		target.visible_message("<span class='warning'>[target] recoils as if hit by something, before suddenly collapsing!</span>",
							"<span class='warning'>The corpse of [target.name] suddenly rises!</span>")
		owning_hallucination.zombify(target)
		has_zombified = TRUE
	else
		qdel(src)

/obj/effect/hallucination/chaser/attacker/blob_zombie/think()
	if(has_zombified)
		return
	return ..()

/obj/effect/hallucination/blob_zombify
	duration = 20 SECONDS

/obj/effect/hallucination/blob_zombify/Initialize(mapload, mob/living/carbon/target, obj/effect/hallucination/blob/blob)
	. = ..()
	var/image/I = image('icons/mob/blob.dmi', target, icon_state = "blob_head")
	I.color = blob.color
	target.client.images += I
	blob.target_blob_head = I
