--[[pod_format="raw",created="2024-03-25 02:14:11",modified="2024-06-24 19:57:10",revision=153]]

function game_info()
	return {
		name = "Trapdoor Solitaire",
		author = "Louie Chapman",
		description = "A spider solitaire variant with Aces acting as wild, but a more restrictive tableau",
		rules = {
			"\tCards can only be stacked in descending values with matching suits",
			"\tWithin a suit, Aces can be placed on any card, and any card can be placed on an Ace. (1 does not count as an Ace)",
			"\tWhen part of a larger stack, Aces are counted as if they were not there, and Stacks can be moved even with Aces within them.",
			"\tTo win, create an ordered stack for each of the 4 suits ranging from 9 to 1",
		},
		desc_score = {
			format = "Wins : %i",
			param = {"wins"}
		},
		api_version = 2
	}
end
