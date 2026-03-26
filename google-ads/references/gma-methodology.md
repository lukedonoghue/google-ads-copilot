# GMA Methodology Authority Model

## Two-Source Knowledge System

This system draws optimization methodology from two knowledge bases via the GMA Knowledge MCP:

### Primary: GMA Founder Training (`search_gma_training`)
- Source: Austin's YouTube videos + internal Loom training sessions
- Authority: Founder. This is the definitive source for how Grow My Ads approaches Google Ads.
- Content: Distilled methodology rules extracted by Claude from raw training content.
- Use for: Bidding strategy, campaign structure, budget allocation, when to pause/scale, PMax configuration.

### Secondary: PPC Copilot Framework (`search_ppc_copilot`)
- Source: 228 structured PPC documents (SOPs, playbooks, checklists, mental models)
- Authority: Expert framework. High-quality second opinion.
- Content: Distilled rules from structured methodology docs.
- Use for: Conversion tracking setup, negative keyword management, RSA composition, landing page CRO.

### Combined: `search_both_advisors`
- Queries both KBs and returns side-by-side results.
- Best for optimization decisions where you want to compare perspectives.
- The response includes a note: "GMA founder methodology is the primary authority."

## Citation Format

When citing methodology in analysis output:

**What the methodology says:** GMA founder training says "if a high-performing campaign is capped by budget, immediately increase budget to capture the opportunity." PPC Copilot's Budget Allocation Mental Model agrees: "budget allocation must be goal-driven — goals determine budget, not the other way around."

Format: `[source name] says "[quoted or closely paraphrased finding]"`

## Low-Relevance Handling

If the KB returns results with relevance scores below 0.4, note: "Methodology doesn't have strong guidance on this topic." Do not force-fit low-relevance results.

## Conflict Resolution

When GMA founder and PPC Copilot disagree:
1. Present both perspectives clearly
2. Default to GMA founder as the primary authority
3. Note the disagreement: "Note: GMA founder methodology and PPC Copilot differ on this point."

## KB Unavailability

If the GMA Knowledge MCP is unreachable:
1. Proceed with analysis using the copilot's built-in playbooks (`google-ads/references/`)
2. Note "KB unavailable" in each finding where methodology would normally be cited
3. Do NOT skip analysis — the built-in playbooks provide solid general PPC knowledge

## How KB Queries Complement Playbooks

The reference playbooks in `google-ads/references/` contain the copilot's general PPC methodology. The GMA Knowledge MCP adds:
- Proprietary methodology specific to Grow My Ads
- Real-world patterns from managing accounts
- Specific decision frameworks that go beyond generic best practices

Think of it as: playbooks = textbook, KB = experienced mentor's advice.
