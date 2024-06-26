--[[pod_format="raw",created="2024-03-17 19:21:13",modified="2024-06-26 16:27:34",revision=3678]]


include "suite_scripts/confetti.lua"
include "cards_api/card_gen.lua"

-- updates card size if it changed
card_width = 45
card_height = 60

available_suits = 4
available_decks = 1

available_rows = 6

all_ranks = {
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"",
	"",
	"",
}

all_face_sprites = {
	[10] = {67,68,69,70,71}
}
	
cards_api_shadows_enable(true)

function game_setup()
	
	game_save = suite_load_save() or {
		wins = 0
	}	
	
	local card_back = suite_card_back()
	
	local card_sprites = card_gen_standard({
		suits = 4,
		ranks = 10,
		rank_chars = all_ranks,
		face_sprites = all_face_sprites
	})
	
	for suit = 1,available_suits do
		for rank = 1,#all_ranks do		
			local c = card_new({
				sprite = card_sprites[suit][min(rank, 10)], 
				back_sprite = card_back,
				x = 240,
				y = 100
			})
			c.suit = suit
			c.rank = rank
		end
	end
	
	local card_gap = 4
	
	local unstacked_cards = {}
	local cards_all = get_all_cards()
	for c in all(cards_all) do
		add(unstacked_cards, c)
	end
	
	
	stacks_supply = {}
	for i = 1,available_rows do
		add(stacks_supply, stack_new(
			{5},
			i*(card_width + card_gap*2) + card_gap + 40, card_gap + 10, 
			{
				reposition = stack_repose_normal(),
				can_stack = stack_can_rule, 
				on_click = stack_on_click_unstack(unstack_rule_decending)
			}))	
	end
	
	
	deck_stack = stack_new(
		{5},
		card_gap+10, card_gap + 10,
		{
			reposition = stack_repose_static(-0.16),
			can_stack = stack_can_on_deck,
			on_click = stack_on_click_reveal
		})
	
	while #unstacked_cards > 0 do
		local c = rnd(unstacked_cards)
		stack_add_card(deck_stack, c, unstacked_cards)
		c.a_to = 0.5
	end
	
	suite_menuitem_init()
	suite_menuitem({
		text = "New Game",
		colors = {12, 16, 1}, 
		on_click = function()
			cards_api_coroutine_add(cocreate(game_reset_anim))
		end
	})
	
	suite_menuitem_rules()
	
	wins_button = suite_menuitem({
		text = "Wins", 
		value = "0000"
	})
	wins_button.update_val = function(b)
		local s = "\fc"..tostr(game_save.wins)
		while(#s < 6) s = "0".. s
		b:set_value(s)
	end	
	wins_button:update_val()

	cards_api_coroutine_add(cocreate(game_setup_anim))
	card_position_reset_all()
end

-- deals the cards out
function game_setup_anim()
	pause_frames(30)
	for i = 1,5 do	
		for s in all(stacks_supply) do
			local c = get_top_card(deck_stack)
			stack_add_card(s, c)
			c.a_to = 0
			pause_frames(3)
		end
		pause_frames(5)
	end

	cards_api_game_started()
end

-- places all the cards back onto the main deck
function game_reset_anim()
	for c in all(deck_stack.cards) do
		c.a_to = 0.5
	end
	stack_collecting_anim(deck_stack, stacks_supply)
	
	game_setup_anim()
end

function stack_can_on_deck(stack, stack2)
	if #stack.cards>=1 then 
		return false
	end

	if #stack2.cards>1 then 
		return false
	end

	return true
end

-- determines if stack2 can be placed on stack
-- for solitaire rules like decending ranks and alternating suits
function stack_can_rule(stack, stack2)
	if s == get_held_stack() then
		return false
	end
	if #stack.cards == 0 then
		return true
	end
	
	local c1 = stack.cards[#stack.cards]
	local c2 = stack2.cards[1]
	
	if c1.suit == c2.suit then
		if c1.rank - 1 == c2.rank or c1.rank>9 or c2.rank>9 then
			return true
		end
	end	
end

-- expects to be stacked from ace to king with the same suit
function stack_can_goal(stack, stack2)
	if stack == get_held_stack() then
		return false
	end

	if #stack2.cards ~= 1 then
		return false
	end
	
	local c1 = stack.cards[#stack.cards]
	local c2 = stack2.cards[1] 
	
	if #stack.cards ~= 0 and c2.rank == 1 then
		return true
	end
	
	
	if #stack.cards > 0 and c1.suit == c2.suit then
		if c1.rank + 1 == c2.rank then
			return true
		end
	end		
end

function stack_on_click_reveal(card)
	if #deck_stack.cards>1 then
		cards_api_coroutine_add(cocreate(deck_draw_anim))
	elseif card then
		set_held_stack(unstack_cards(card))
	end
end

function deck_draw_anim()
	local s = deck_stack.cards

	for i=1,#stacks_supply do
		if #s > 0 then
			local c = s[#s]
			stack_add_card(stacks_supply[i], c)
			c.a_to = 0

			pause_frames(3)
		end
	end
end

function unstack_rule_decending(card)
	local s = card.stack.cards
	local i = has(s, card)
	
	local current_rank = card.rank

	-- goes through each card above clicked card to see if it fits the rule
	for j = i+1, #s do
		local next_card = s[j]
		
		-- either rank matches, not decending by 1
		if next_card.suit ~= card.suit then 
			return false
		end	
	
		if next_card.rank<=9 then
			if next_card.rank+1 ~= current_rank and current_rank<=9 then
				return false
			end
		else
			
		end
	
		card = next_card -- current card becomes previous card
		
		if next_card.rank<=9 then
			current_rank = card.rank
		end
	end
	
	return true
end

function game_draw(layer)
	if layer == 0 then
		cls(3)
	elseif layer == 2 then
		confetti_draw()
	end
end

function game_update()
	confetti_update()
end




-- winning things
function game_win_anim()
	confetti_new(130,135, 100, 10)
	pause_frames(25)
	confetti_new(350,135, 100, 10)
end

function game_win_condition()
	local stack_count = 0

	for stack in all(stacks_supply) do
		local i, len = 1, #stack.cards
		while i <= len do
			local card = stack.cards[i]
			i += 1 -- prepare next card

			-- for every 9 found
			if card.rank == 9 then
				local suit = card.suit
				local r = 8 -- start by searching for 8
				
				while i <= len -- haven't reached end of stack
				and (stack.cards[i].rank == r -- card has expected rank
					or stack.cards[i].rank > 9) -- or an Ace
				and stack.cards[i].suit == suit -- card has same suit
				and r > 0 do -- haven't haven't checked rank 1 yet
				
					if stack.cards[i].rank <= 9 then
						r -= 1 -- 1 rank lower, ignore Aces
					end
					i += 1 -- next card
				end
				
				-- failed to find all the ranks
				if(r > 0) return false
				
				-- increase found count
				stack_count += 1
			end
		end
	end
	
	-- if count is at (or somehow above) the expected value
	return stack_count >= available_suits * available_decks
end

function game_count_win()
	game_save.wins += 1
	wins_button:update_val()
	suite_store_save(game_save)
	cards_api_coroutine_add(cocreate(game_win_anim))
end
