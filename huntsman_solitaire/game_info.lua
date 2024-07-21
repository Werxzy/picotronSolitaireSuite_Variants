--[[pod_format="raw",created="2024-03-25 02:12:03",modified="2024-06-24 19:57:23",revision=1557]]

function game_info()
	return {
		name = "Huntsman Solitaire",
		author = "Louie Chapman",
		description = "Hunt down the four matching ranked cards to win!",
		rules = {
			"\tCards are stacked with either decreasing or matching values. However, a stack can only be moved when following either rule, and not both.",
			"\tAces can be placed on any card, and any card can be placed on Aces.",
			"\tWhen clicked, the draw pile on the right will deal a card to every column.",
			"\tThe reserve deck on the left contains cards that can be played onto any valid position, but cards can not be played onto the reserve deck.",
			"\tCards can be stacked on both the draw deck, and/or reserve deck, when they have no cards remaining.",
			"\tTo win, match four-of-a-kind on each of the cards on the top of the tableau.",
			},
		desc_score = {
			format = "Wins : %i",
			param = {"wins"}
		},
		api_version = 2,
		order = 4
	}
end
