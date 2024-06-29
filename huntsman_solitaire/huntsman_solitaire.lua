--[[pod_format="raw",created="2024-03-22 19:08:40",modified="2024-06-29 20:50:26",revision=3865]]

include "suite_scripts/confetti.lua"
include "cards_api/card_gen.lua"

-- updates card size if it changed
card_width = 45
card_height = 60

tableau_width = 4
tableau_initial_deal = 5

reserve_initial_deal = 8

foundation_targets = 4

all_suit_colors = {
	{1, 1,16,12},
	{8, 24,8,14},
	{1, 1,16,12},
	{8, 24,8,14}
}

rank_count = 13 -- adjustable

function game_setup()

	-- save data is based on lua file's name
	game_save = suite_load_save() or {
		wins = 0
	}	
	
	local card_gap = 4
	local x_offset = 70
	
	-- draw pile
	deck_stack = stack_new(
		{5},
		x_offset+(5)*(card_width + card_gap*2)+10, card_height - 30,
		{
			reposition = stack_repose_deck,
			can_stack = stack_can_on_deck, 
			on_click = stack_on_click_reveal
		})
	
	local card_back = suite_card_back()
	
	local card_sprites = card_gen_standard({
		suits = 4, 
		ranks = rank_count,
		suit_colors = all_suit_colors
	})

	for suit = 1,4 do
		for rank = 1,rank_count do		
			local c = card_new({
				sprite = card_sprites[suit][rank], 
				back_sprite = card_back,
				stack = deck_stack,
				a = 0.5
			})
			c.suit = suit
			c.rank = rank
		end
	end
	
	stack_quick_shuffle(deck_stack)	
	
	
	stacks_supply = {}
	for i = 1,tableau_width do
		add(stacks_supply, stack_new(
			{5},
			i*(card_width + card_gap*2) + card_gap + x_offset, card_gap + card_height + 10, 
			{
				reposition = stack_repose_normal(nil,nil,160),
				can_stack = stack_can_rule,
				on_click = stack_on_click_unstack(unstack_rule_decending, unstack_rule_face_up),
				on_double = stack_on_double_goal}
			))
	end
	
	-- foundation piles
	stack_goals = {}
	for i = 0,3 do
		add(stack_goals, stack_new(
			5,
			(i+1)*(card_width + card_gap*2) + card_gap + x_offset, 5,
			{
				reposition = stack_repose_foundations,
				can_stack = stack_can_goal
			}))
	end
	
	-- reserve pile
	deck_reserve = stack_new(
		{5},
		x_offset-card_gap, card_height - 30,
		{
			reposition = stack_repose_reserve,
			can_stack = stack_can_on_deck, 
			on_click = stack_on_click_reserve, 
			on_double = stack_on_double_goal
		})
	

	suite_menuitem_init()
	suite_menuitem({
		text = "New Game",
		colors = {12, 16, 1}, 
		on_click = function()
			cards_api_coroutine_add(game_reset_anim)
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

	cards_api_coroutine_add(game_setup_anim)
	card_position_reset_all()
end

-- checks each foundation pile for a unique rank
-- also you can't have aces
function is_unique_rank(c)
	if c.rank==1 then return false end

	for s in all(stack_goals) do
		local c1 = s.cards[1]
		
		if c1 and c1~=c then 
			if c1.rank==c.rank then 
				return false
			end
		end
	end
	
	return true
end

-- deals the cards out
function game_setup_anim()
	deck_reserve.has_been_emptied = false
	deck_stack.has_been_emptied = false
	
	is_setting_up = true

	-- deal out goal cards
	pause_frames(30)
	local i=1
	while i<=4 do
		local s=stack_goals[i]
		local c=get_top_card(deck_stack)
		
		stack_add_card(s, c)
		c.a_to = 0
		pause_frames(20)
		
		if is_unique_rank(c) then 
			i+=1
		else
			pause_frames(20)
			
			stack_add_card(deck_stack, c, rnd(#deck_stack.cards+1)\1+1)
			c.a_to = 0.5
			
			for c in all(deck_stack.cards) do 
				card_to_top(c)
			end	
		
			pause_frames(30)
		end
	end
	
	-- deal out reserve
	for i=1,reserve_initial_deal do
		local c = get_top_card(deck_stack)
		stack_add_card(deck_reserve, c)
		c.a_to =i==reserve_initial_deal and 0 or 0.5 
		pause_frames(5)
	end

	-- deal out tableau
	pause_frames(20)
	for i = 1,tableau_initial_deal do	
		for s in all(stacks_supply) do
			local c = get_top_card(deck_stack)
			stack_add_card(s, c)
			c.a_to =i==tableau_initial_deal and 0 or 0.5 
			pause_frames(3)
		end
		pause_frames(5)
	end
	
	is_setting_up = false

	cards_api_game_started()
end

-- places all the cards back onto the main deck
function game_reset_anim()	
	for c in all(deck_stack.cards) do 
		c.a_to = 0.5
	end
	
	deck_stack.has_been_emptied = false
	
	stack_collecting_anim(deck_stack, stacks_supply, stack_goals, deck_reserve)
	
	game_setup_anim()
end

function game_action_resolved()
	if not get_held_stack() then
		for s in all(stacks_supply) do
			local c = get_top_card(s)
			if(c) c.a_to = 0
		end
		
		local top = deck_reserve.cards[#deck_reserve.cards]
		if not is_setting_up and top and top.a_to~=0 then 
			top.a_to=0
		end
		
		for s in all(stack_goals) do 
			if #s.cards>=4 then
				for c in all(s.cards) do 
					c.a_to=0.5
				end
			end
		end
		
		if #deck_reserve.cards==0 then 
			deck_reserve.has_been_emptied = true
		end
		
		-- set the deck to be fully empty
		if #deck_stack.cards==0 then 
			deck_stack.has_been_emptied=true
		end	
	end
end

function game_win_anim()
	confetti_new(130,135, 100, 10)
	pause_frames(25)
	confetti_new(350,135, 100, 10)
end

function game_win_condition()
	for g in all(stack_goals) do
		if #g.cards~=4 then return false end
	end
	return true
end

function game_count_win()
	game_save.wins += 1
	wins_button:update_val()
	suite_store_save(game_save)
	cards_api_coroutine_add(game_win_anim)
end

function stack_repose_deck(stack)
	if stack.has_been_emptied then 
		stack_repose_normal()(stack)
	else
		stack_repose_static(-0.16)(stack)
	end
end

function stack_repose_reserve(stack)
	if stack.has_been_emptied then 
		stack_repose_normal()(stack)
	else
		stack_repose_normal(3)(stack)
	end
end

-- reposition calculation that has fixed positions
function stack_repose_foundations(stack)
	local y = stack.y_to
	for i, c in pairs(stack.cards) do
		c.x_to = stack.x_to
		c.y_to = y
		
		-- if the stack is full then only have one pile
		y += #stack.cards>=4 and 0 or 2
	end
end

-- determines if stack2 can be placed on stack
-- for solitaire rules like decending ranks and alternating suits
function stack_can_rule(stack, stack2)
	if #stack.cards == 0 then
		return true
	end
	
	local c1 = stack.cards[#stack.cards]
	local c2 = stack2.cards[1]
	
	-- if the suits are alternating AND the rank is one below
	if c1.rank - 1 == c2.rank then -- alternating suits (b,r,b,r) (0,1,2,3)
		return true
	end
	
	-- if both ranks are the same then allow placement
	-- or if either are an ace
	if c1.rank == c2.rank or c1.rank==1 or c2.rank==1 then return true end
end

-- goal stacks
-- in this case , just looking for four of a kind
function stack_can_goal(stack, stack2)
	if #stack2.cards ~= 1 then
		return false
	end
	
	local c1 = stack.cards[#stack.cards]
	local c2 = stack2.cards[1] 
	
	if c1.rank==c2.rank then
		return true
	end
end

-- the animation for drawing cards <3
function deck_draw_anim()
	local s = deck_stack.cards

	for i=1,#stacks_supply do
		if #s > 0 then
			-- normal viewing
			local c = s[#s]
			stack_add_card(stacks_supply[i], c)
			c.a_to = 0

			pause_frames(3)
		end
	end
end

function stack_can_on_deck(stack, stack2)
	if stack.has_been_emptied then 
		return stack_can_rule(stack,stack2)
	end
	
	return false
end

-- when the reserve pile is clicked
function stack_on_click_reserve(card)
	if deck_reserve.has_been_emptied then 
		stack_on_click_unstack(unstack_rule_decending)(card)
	else
		stack_on_click_unstack(card_is_top)(card)
	end
end

-- when the draw pile is clicked
function stack_on_click_reveal(card)
	if deck_stack.has_been_emptied then
		stack_on_click_unstack(unstack_rule_decending)(card)
	else
		cards_api_coroutine_add(deck_draw_anim)
   end
end


function stack_on_double_goal(card)
	-- only accept top card (though could work with multiple cards
	if card and card_is_top(card) then 
		local old_stack = card.stack
		-- create a temporary stack
		local temp_stack = unstack_cards(card)
		
		-- attempt to place on each of the goal stacks
		for g in all(stack_goals) do
			if g:can_stack(temp_stack) then
				stack_cards(g, temp_stack)
				temp_stack = nil
				break
			end
		end
			
		-- if temp stack still exists, then return card to original stack
		if temp_stack then
			stack_cards(old_stack, temp_stack)
		end
	end
end

function unstack_rule_decending(card)
	local s = card.stack.cards
	local i = has(s, card)
	
	-- if the card is an ace , see if it could move the cards beneath it
	if card.rank==1 and i~=#s then  return unstack_rule_decending(s[i+1]) end
	
	-- first check if the card is a pair, triple, or four of a kind
	local n_of_kind = 0
	
	-- goes through each card above clicked card to see if it fits the rule
	for j = i+1, #s do
		local next_card = s[j]	
		
		if n_of_kind>=0 and card.rank==next_card.rank then 
			n_of_kind+=1
		else
			-- if there's already been more than 1 matching card
			-- then you can't have a straight
			if n_of_kind>0 then return false end
			
			-- otherwise set it to -1
			n_of_kind = -1
		end
	
		if n_of_kind==-1 then
			if next_card.rank+1 ~= card.rank then
				return false
			end
		end
		card = next_card -- current card becomes previous card
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
