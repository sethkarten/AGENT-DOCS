# Writing constraints for paper paragraphs

Generated LaTeX paragraphs must not read like AI output. Rules:

## Hard bans
- **No em-dashes** (`—` or `--` in LaTeX that renders as em-dash). Use comma, semicolon, period, or parentheses instead.
- **No AI connectives**: "Indeed,", "Moreover,", "Furthermore,", "In particular,", "It is worth noting that,", "We posit", "We endeavor", "We propose to", "To this end", "With this in mind", "As such,", "That said,".
- **No hedging filler**: "suggests that", "may indicate", "appears to", "seems to". If the data shows X, say "X". If you mean "we observe X with N=3 seeds", say that.
- **No wishful generalization**: "This demonstrates the power of evolution", "Our approach showcases", "Our framework highlights".

## Voice
- Active, direct. "AutoEvolve reduces button presses by 38%." not "A reduction in button presses is observed."
- One claim per sentence. Multiple short sentences beat one long one.
- Technical, not promotional. State numbers. Name the figure.

## Numbers
- Always cite concrete numbers (medians, counts, ratios) from the JSON summary.
- Prefer "Phase 1 reaches the Stone Badge in 4184 cumulative button presses (median across n=4 seeds), against 6487 for the minimal baseline."
- Over: "Phase 1 was significantly more efficient than baseline."

## Figure references
- Use `\cref{fig:c1_memory}` or `\figref{}` (choose one style consistent across chunks). Prefer `\cref` with `cleveref`.
- Don't restate captions in the paragraph.

## Length
- Each claim section: one paragraph, 4 to 8 sentences, 80 to 160 words.
- If you need more, you are over-explaining. Tighten.

## Limitations
- Mention caveats honestly in a trailing sentence, not buried in a footnote.
- "On Red, phase 2 continued regresses relative to baseline after the second gym; we attribute this to newly created subagents crowding out inherited ones (\cref{fig:...})."

## Example good paragraph (style target)

> Figure \ref{fig:c2_segment} compares matched route segments. Phase 1 agents traverse open routes with 14 to 45 percent of the button presses used by the minimal baseline (median across seeds). The gap closes in gym interiors where dialogue and menu steps dominate over navigation. The dominant invoked skills are \texttt{move\_to\_coords}, \texttt{navigate}, and \texttt{bfs\_nav}, all BFS variants; the skill library specializes in pathfinding because that is where the harness pays the highest local reward. On Red, the minimal baseline issues nine hundred \texttt{run\_code} calls per run, substituting inline scripting for a persistent skill library (\cref{fig:c2_invocations}).

## Example bad paragraph (avoid)

> Indeed, our experiments reveal that the AutoEvolve framework demonstrates a remarkable ability to generate pathfinding skills — in particular, the agents appear to develop an impressive repertoire of BFS-based navigation tools which suggests that evolution is capable of yielding meaningful improvements over the baseline. It is worth noting, however, that in some cases the baseline may perform comparably.
