-- Format: <tn> is replaced with actual team name


local messages = {
	'<tn> has been obliterated.',
	'<tn> has been liquidated.',
	'<tn> has been exterminated.',
	'<tn> has been eradicated.',
	'<tn> has been annihilated.',
	'<tn> has been dishabilitated.',
	'<tn> has been devastated.',
	'<tn> has been deactivated.',
	'<tn> has been dominated.',
	'<tn> has gone to a better place.',
	'<tn> played Russian Roulette with a semi-automatic rifle.',
	'<tn> has been deported to Siberia.',
	'<tn> has mislaid his towel.',
	'<tn> was (mostly) harmless.',
	'<tn>: So long, and thanks for all the fish!',
	'<tn> nipples exploded with delight.',
	'<tn> is pushing up the daisies.',
	'<tn> will not buy this record, it is scratched.',
	'<tn> fought like a dairy farmer.',
	'<tn> could really use a breath mint.',
	'<tn> has gone missing. The last transmission received was the word STENDEC',
	'<tn> is waiting for Godot to arrive...',
	'<tn> has been joolsed down',
	'Do, or do not. There is no <tn>',
	'<tn> danced with the devil in the pale moonlight',
	'<tn> was shaken, not stirred',
	'Brave <tn> was not at all afraid to be killed in nasty ways',
}

-- <side> is replaced by the the actual side.
local defaultmessages = {
	'<side> forces have gone to a better place.',
	'<side> vermin have been exterminated.',
	'<side> forces have been obliterated.',
}

-- <side> is replaced by the the actual side. In case a player resigns, the system has no information about the name
local resignedmessages = {
	'<side> forces have gone to a better place.',
	'<side> vermin have retreated',
	'<side> rascals have surrendered.',
	'<side> forces have laid down their arms.',
	'<side> rapscallions gave up',
	'<side> scoundrels have deserted',
	'<side> thugs ran away',
}

return messages, defaultmessages, resignedmessages

