
.PHONY: vault.clean vault.init \
        flashcards.parse \
        flashcards.query \
        flashcards.review \
        flashcards.frontmatter \
        flashcards.manual \
		usage help

.DEFAULT_GOAL := usage
VAULT_DIR := /home/js/projects/nvim-notepad/notepad_test_vault
TEST_FILE := $(VAULT_DIR)/test.md
NVIM := /home/js/setup/nvim/nvim-linux-x86_64/bin/nvim

# ---------- Vault setup ----------


usage help:
	@echo ""
	@echo "Flashcards – Manual Test Targets"
	@echo "================================"
	@echo ""
	@echo "Vault:"
	@echo "  make vault.init            	Create dummy Obsidian test vault"
	@echo "  make vault.clean           	Remove test vault"
	@echo ""
	@echo "Flashcards:"
	@echo "  make flashcards.parse      	Parse markdown into flashcards"
	@echo "  make flashcards.query      	Query due flashcards"
	@echo "  make flashcards.review     	Apply FSRS rating and persist state"
	@echo "  make flashcards.frontmatter 	Inspect resulting frontmatter"
	@echo "  make flashcards.store          Deserialize / serialize flashcard metadata"
	@echo ""
	@echo "All:"
	@echo "  make flashcards.manual     	Run all manual flashcard checks"
	@echo ""
	@echo "Examples:"
	@echo "  make vault.init"
	@echo "  make flashcards.review"
	@echo "  make flashcards.manual"
	@echo ""

vault.clean:
	rm -rf $(VAULT_DIR)

vault.init: vault.clean
	mkdir -p $(VAULT_DIR)
	printf "%s\n" \
	"---" \
	"notepad:" \
	"  flashcard:" \
	"    fsrs:" \
	"      stability: 2.5" \
	"      difficulty: 5.0" \
	"      last_review: 1700000000" \
	"      due: 1" \
	"---" \
	"" \
	"# Flashcard Test Note" \
	"" \
	"## Inline flashcard" \
	"What is 2+2? :: 4" \
	"" \
	"## Q/A style flashcard" \
	"Q:: What does TCP stand for?" \
	"A:: Transmission Control Protocol" \
	"" \
	"## Callout flashcard" \
	"> [!flashcard]" \
	"> What is HTTP?" \
	">" \
	"> Hypertext Transfer Protocol" \
	"" \
	"## Non-flashcard callout" \
	"> [!note]" \
	"> This is just a note." \
	> $(TEST_FILE)
	@echo "✔ Test vault created at $(VAULT_DIR)"


# ---------- Individual tests ----------

flashcards.parse: vault.init
	$(NVIM) --headless +"lua << 'LUA'
	local parser = require('notepad.features.flashcards.parser')
	local lines = vim.fn.readfile('$(TEST_FILE)')
	local cards = parser.parse(lines)
	
	assert(#cards == 3, 'expected 3 flashcards, got ' .. #cards)
	
	for i, c in ipairs(cards) do
	  print(i .. ':', c.front, '=>', c.back)
	end
	LUA" +qa
	@echo "✔ flashcards.parse passed"

flashcards.query: vault.init
	$(NVIM) --headless -c "lua \
	local query = require('notepad.features.flashcards.query'); \
	local cards = query.due_today('$(VAULT_DIR)'); \
	print('Found cards:', #cards); \
	assert(#cards > 0, 'expected due cards'); \
	for i, c in ipairs(cards) do \
	  print(i .. ':', c.front); \
	end" \
	-c qa
	@echo "✔ flashcards.query passed"

flashcards.review: vault.init
	$(NVIM) --headless -c "lua \
	local review = require('notepad.features.flashcards.review'); \
	local query = require('notepad.features.flashcards.query'); \
	local cards = query.due_today('$(VAULT_DIR)'); \
	assert(#cards > 0, 'no due cards found'); \
	local session = review.start(cards[1]); \
	local next_state = review.apply_rating(session, 3); \
	assert(type(next_state.stability) == 'number'); \
	assert(type(next_state.difficulty) == 'number'); \
	assert(next_state.due > os.time()); \
	print(vim.inspect(next_state));" \
	-c qa
	@echo "✔ flashcards.review passed"

flashcards.frontmatter:
	@echo "== Frontmatter after review =="
	sed -n '1,40p' $(TEST_FILE)

flashcards.store: vault.init
	$(NVIM) --headless -c "lua \
	local store = require('notepad.features.flashcards.store') \
	store.deserialize() \
	local a = store.resolve('notes/a.md') \
	local b = store.resolve('notes/a.md') \
	assert(a.id == b.id) \
	store.record_rename('notes/a.md', 'notes/b.md') \
	local c = store.resolve('notes/b.md') \
	assert(c.id == a.id) \
	store.serialize()" \
	-c qa
	@echo "✔ flashcards.store passed"

# ---------- Aggregate ----------

flashcards.manual: \
	vault.init \
	flashcards.parse \
	flashcards.query \
	flashcards.review \
	flashcards.frontmatter
	@echo "✔ All manual flashcard checks passed"

