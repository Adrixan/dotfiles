# Toolbox

Techniques regrouped and restated in own words; source: Roy Peter Clark, *Writing Tools* (2008). Each entry: what to do, how to spot the need (Check), an own example. Use the labels in coaching so Peter can name the move. German counterparts: `deutsch.md`.

## 1. Sentence engine

**Lead with the actor and the action.** Put subject and verb of the main clause early and close together; let modifiers, reasons and details follow. Delay the main clause on purpose only for suspense, after a run of plain sentences.
Check: count words between subject and verb; more than about eight means the reader holds a dangling subject.
Example: "A patch that changes how the parser treats nested quotes in configuration files submitted by tenants could break imports" → "The patch could break tenant imports: it changes how the parser treats nested quotes in configuration files."

**Stress positions.** The end of a sentence carries the most weight, the beginning the second most, the middle the least. Same for paragraphs. Hide attributions, dates and qualifiers in the middle.
Check: is the last word of each key sentence the word that matters?
Example: "The ridge was icy, so we turned back at 2,900 m, according to the log" → "According to the log, we turned back at 2,900 m: the ridge was ice."

**Choose verb voice by effect.** Active shows who acts; passive puts the receiver of the action in front (victims, affected data, the thing that changed); forms of "to be" connect ideas and definitions. Mistakes and apologies go in the active voice.
Check: mark each verb as active, passive or linking; a page of passive and "there is/are" reads like nobody is responsible.
Example: "There were several warnings in the log" → "The log shows four warnings." Deliberate passive: "Twelve student accounts were exposed" (the students matter, not the script).

**Adverbs must change the verb, never repeat it.** "Whispered quietly" repeats; "smiled bitterly" changes the meaning. Replace weak verb plus adverb with a precise verb.
Check: search for -ly (and German intensifiers); delete each and see whether meaning is lost.
Example: "ran quickly up the slope" → "charged up the slope"; "totally destroyed" → "destroyed".

**Few progressive and gerund forms.** Strings of -ing words blur into each other and slow the sentence; simple present or past is crisper. The German twin is the -ung noun pile (see `deutsch.md`).
Example: "Finding the cause, the team is now working on restarting and monitoring the service" → "The team found the cause, restarted the service and now monitors it."

**Long sentences on purpose.** A long sentence works when its main clause comes first, it moves in time order or builds a list, it describes something long (a route, a process, an inventory), and it sits among shorter sentences. It needs more editing per word than a short one.
Example: "The route climbs from the hut through larch forest, crosses two scree fields, follows the ridge for 3 km and drops 900 m to the valley before the afternoon storms build."

**Parallel form for parallel ideas; break the pattern at the end.** Equivalent items take the same grammatical shape. Repetition builds momentum; a changed last element gets the emphasis.
Check: lists whose items mix nouns, infinitives and clauses.
Example: "Patch the server, rotate the keys and the logs should be reviewed" → "Patch the server, rotate the keys, review the logs." With a twist: "We checked the firewall, the proxy, the DNS, and finally the cable."

**Punctuation sets pace.** Periods stop the reader (many periods slow the text for clarity, emotion or suspense); commas slow briefly; semicolons divide large linked chunks; a colon announces what follows; parentheses detour. Under Peter's rules the colon takes over the dash's punch-line job.
Example: "One thing survived the reinstall: the cron job nobody documented."

## 2. Words

**Plain words where it gets hard.** Use the shortest common word that is accurate, and the simplest sentences at the most complex point of an explanation. Clarity starts upstream: the writer must understand the subject before trying to explain it; "here is how it works" is a good test sentence.
Example: "The implementation of multi-factor authentication mechanisms will facilitate a reduction in account compromise incidents" → "A second login factor stops most stolen passwords from working."

**Give key words their own space.** Avoid unintended repetition of distinctive words in a paragraph; keep building-block words (server, ridge, Schüler) and technical terms constant; keep "said" ("sagte") as the default dialogue tag.
Check: a distinctive word ("cascade", "brittle") twice within a few lines; a technical term swapped for a synonym (key/secret/token for one thing).

**Use the whole vocabulary, even on serious topics.** Readers understand more words than writers usually use; a precise uncommon word, defined by context, rewards attention. Wordplay is possible in serious texts when it sharpens meaning; skip the first pun that comes to mind, since every other writer finds it too.

**Specific detail that tells.** Collect the concrete, checkable particular (the exact error, the 3 a.m. timestamp, the brand of the cracked headlamp) and use the one that reveals character or meaning. Prefer details from observation over invented ones; appeal to more senses than sight in narrative.
Check: could this sentence appear unchanged in a text about a different case? Then it lacks a specific.
Example: "The student was nervous" → "The student had rewritten the first line of her answer five times; the eraser had worn through the page."

**Names carry information.** Real names of people, places, tools and things suggest history, origin and character; get them right and use them instead of generic labels ("Kalkalpen" beats "the mountains", "Tumbleweed snapshot 20261108" beats "the latest update").

**Fresh images or plain statement.** A phrase you have seen in print a hundred times does the thinking for you. Either find a new image (brainstorm several, keep the one that fits) or write it straight. Also beware stock frames ("the dream became a nightmare", "David against Goliath", "hackers in hoodies"), which are clichés of vision.
Example: "The project is on thin ice" → "The project has two weeks of budget left and no signed contract."

**Riff on other people's language.** Borrow and transform a known phrase, title or saying, credit when the source is not common knowledge, and make the twist carry new meaning (classroom titles, posts, slogans).

## 3. Rhythm and proportion

**Sentence length is tempo.** Long sentences carry the reader along; short ones stop. Slow down (short sentences, more periods) for complex content, emotion or suspense; speed up for narrative flow. Match length to content: a brief event gets a brief sentence.

**Paragraph length by unit of thought.** One paragraph, one idea. A one-line paragraph is an emphasis device and loses force when used often; a wall of text hides its points. On screens and in posts paragraphs run shorter.

**Count elements with intent.** One item: force. Two: comparison or contrast. Three: completeness. Four or more: inventory, abundance. Then order them (strongest last, or chronological).
Check for agent tics: every list exactly three items long, adjective triplets ("fast, secure and scalable").

**Back off or show off.** The more serious the subject, the more the writer recedes and lets facts work (understatement); the lighter the subject, the more style may show (hyperbole, play). Peter's security advisories, incident reports and anything touching minors: back off.

**Move up and down the ladder of abstraction.** Concrete examples at the bottom, ideas and values at the top; good texts connect both. Avoid the middle rungs, where jargon and bureaucratic abstraction live ("stakeholders", "Ressourcen", "Lernsettings").
Check: each abstract claim followed by a concrete case; each anecdote tied to the idea it illustrates.
Example: "Digital sovereignty matters for schools" + "When the cloud provider changed its terms in August, the school lost access to three years of student portfolios for nine days."

**Tune the voice deliberately.** Voice is the sum of choices: level of language, grammatical person, source of allusions, amount of figurative language, typical sentence structure, distance from neutrality, conventional or experimental framing. Changing one dial changes the voice; in coaching, name the dials Peter uses and keep them.

## 4. Structure

**Plan the parts.** Know beginning, middle and end, and name the big parts for the reader (headings, numbered steps, signposts) when the text is long. A plan can be three lines.

**Report or story.** Reports deliver information and let readers scan; stories deliver experience and put the reader in the scene. To turn a report into a story: who becomes a character, what becomes action and plot, where becomes setting, when becomes sequence, why becomes motive, how becomes the process the reader watches. Mixing works: a short scene opens a report, then the explanation follows, with the scene's person returning at the end.

**Dialogue as action, quotes with a job.** In narrative, dialogue moves the story and reveals people. In reports, a quote earns its place only if it adds a human voice, explains, frames a dilemma, adds facts, reveals the speaker or leads to what comes next; paraphrase the rest.

**Reveal character through evidence.** Show a person through what they do, say, own, wear and how others react, rather than through adjectives ("ambitious", "kind").

**Juxtapose.** Place two things side by side so each comments on the other (a statement next to the data that contradicts it, a festive setting next to bad news). This is Peter-compatible irony: no corrective metaphor needed, the arrangement does the work.

**Foreshadow.** Plant early what pays off later (an object, a remark, a risk) so the ending feels earned. In explanations: name early the question the text will answer.

**Internal cliffhangers.** End sections on an open question or an unresolved moment to pull the reader into the next part (serial posts, chapters, interactive fiction nodes, multi-part lessons).

**Drive with a key question.** Organise the piece around one question the reader wants answered (will it work, who did it, what does it cost); answer it late in narrative, early in reports.

**Rewards along the way.** In long texts place small payoffs at intervals (a vivid detail, a surprising number, a quote, a joke) so readers keep going; especially in the middle, where attention drops.

**Repetition with intent.** Recurring words, images or motifs give rhythm and tie a long text together; unplanned repetition reads as carelessness.

**Camera distance.** Vary the view: overview (the whole valley, the whole network), establishing shot (the setting), middle distance (people interacting), close-up (a face, a single log line), extreme close-up (the one telling detail). Move in and out with purpose.

**Scenes.** Narrative realism builds from scenes: a place, a time, people, action, dialogue, point of view. Gather material for scenes on purpose (what happened, in what order, who said what).

**Short forms: every syllable works.** Posts, abstracts, headlines, subject lines, slides and captions gain from brevity: focused force, room for wit, polish. Rewrite them more often per word than long texts.

**Archetypes over stereotypes.** Deep story patterns (journey and return, the quest, loss and recovery, the trickster, rebirth) give resonance and can be fulfilled or subverted; stereotypes (the lazy official, the lone hacker genius, the naive pupil) flatten people and mislead.

**Write toward an ending.** Know the ending early. Options: close the circle (return to the opening image or person), tie back to a detail from the middle, end on the last moment in time or the last place in space, deliver the payoff, give an epilogue, end on the solution after a problem frame, use a quote that truly sums up, look ahead to consequences, or tell the reader what to do next. For agent reports the ending is the decision, the next step or the open question.

## 5. Process and habits

**Mission statement.** Before a big piece write a short paragraph: what I want this text to do, for whom, in which form. Reread it when stuck.

**Delay as rehearsal.** Most writers delay; turn it into preparation (lists, notes, talking it through, a rough paragraph). Draft early, since drafting shows what research is still missing; quality comes from revision; daily routines (Peter's early mornings) beat waiting for inspiration; prepare the desk and the files the day before.

**Prepare before the assignment arrives.** Build background knowledge on recurring topics so a deadline piece can draw on it.

**Read for form as well as content.** Read admired texts asking how they are built: openings, endings, sentence lengths, where the facts sit; annotate in the margin; read outside the field.

**Save string.** Keep a running file per topic for clippings, phrases, facts and ideas (an Obsidian note per future piece); a full file becomes a draft.

**Break long projects into parts.** A small daily quota finishes big work: one page of about 250 words a day is a dissertation draft within a year. Chapters, scenes and sections are units to finish one at a time.

**Use helpers.** A first reader who encourages, one who knows the subject, one who edits, one who protects writing time; tell each what kind of reading you need ("is the argument clear?" rather than "any thoughts?").

**Hold back the inner critic early.** Draft first, judge later. Harsh self-editing during the first draft stalls it.

**Learn from critics.** Do not argue taste and do not defend by reflex: explain what you were trying to do, ask what got in the way, turn the debate into a conversation.

**Workflow stages.** Notice something worth writing about, explore it, collect evidence, find the real focus, select only the best material, see the shape, draft, revise and clarify. Most problems in a draft trace back to a skipped stage (usually focus or selection).
