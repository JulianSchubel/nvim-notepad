#parse
:lua print(vim.inspect(require("notepad.features.flashcards.parser").parse(vim.fn.readfile("/home/js/projects/nvim-notepad/notepad_test_vault/test.md"))))
#query due cards
:lua print(vim.inspect( require("notepad.features.flashcards.query") .due_today("/tmp/notepad-test-vault")))

#review flow
:lua local review = require("notepad.features.flashcards.review") local cards = require("notepad.features.flashcards.query") .due_today("/tmp/notepad-test-vault") local session = review.start(cards[1]) local next_state = review.apply_rating(session, 3) print(vim.inspect(next_state))

#after one review with rating GOOD(3) frontmatter should look like
notepad:
  flashcard:
    fsrs:
      stability: <number>
      difficulty: <number>
      last_review: <fixed time if with_time>
      due: <last_review + N days>



