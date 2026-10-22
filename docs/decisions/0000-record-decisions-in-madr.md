---
status: accepted
date: 2026-10-22
decision-makers:
---

# Record decisions as MADR 4.0 Bare Minimal files, with a backlog beside them

## Context and Problem Statement

The reasons behind this repo's choices end up in commit messages, pull
requests and chat, where a person or an agent can't find them later. Nor
can a reader tell whether a decision still holds. How should this repo
record its decisions?

## Considered Options

- MADR 4.0 Bare Minimal in `docs/decisions/`, with a backlog beside it
- MADR 4.0's full template for every record
- No fixed format: notes in pull requests, issues or a wiki

## Decision Outcome

Chosen option: "MADR 4.0 Bare Minimal in `docs/decisions/`, with a backlog
beside it". This is the layout DevPartners uses across its repos. Each
record has four headings, so a small decision stays small. Status and date
sit in front matter, where a command can read them.

The rules:

- **Records** live in `docs/decisions/`, flat, named
  `NNNN-title-with-dashes.md` with the next free number. A number is never
  reused. Copy [adr-template.md](adr-template.md) to start one.
- **Front matter:** `status` and `date` are required, and `decision-makers`
  is expected.
  - `status` is `proposed`, `accepted`, `rejected`, `deprecated`, or
    `superseded by ADR-NNNN`.
  - `date` is the day the record was decided or last revised. A change of
    status alone doesn't change it.
- **Sections:** Context and Problem Statement, Considered Options, Decision
  Outcome, and Consequences under it, none left empty. Add MADR's optional
  sections when they earn their place: Decision Drivers, Confirmation, Pros
  and Cons of the Options, and More Information.
- **Changing a record:** a record says what holds now, so when a decision
  changes, its record is changed in place, and git history keeps the
  earlier wording. The one rule: nobody changes a record without checking
  with its decision-makers first. A question about a record that isn't
  settled yet goes in the backlog, naming the record. When a new record
  replaces an old one, the old one's status becomes
  `superseded by ADR-NNNN`.
- **Index:** [README.md](README.md) has one row per record, with its status.
- **Backlog:** questions nobody has decided yet go in
  `docs/decision-backlog/`, one unnumbered file each, indexed in that
  folder's README. A backlog item is not a `proposed` record.
- **Lint:** the repo's root markdownlint config covers these files too.
  There is no config inside either decision folder.
- **Check:** it follows this record. If an amendment here allows other
  statuses or requires other sections, put them in
  `docs/decisions/.validate-decisions` in the same commit, as the check's
  `--help` describes.

### Consequences

- Good, because whether a decision is in force can be checked by a command.
- Good, because each record says what holds now, and git history keeps
  every earlier version.
- Bad, because a decision now means writing a short file as well as making
  the change.

### Confirmation

Run DevPartners agent-kit's check from the repo root:

```bash
<agent-kit>/scripts/validate-decisions.sh .
```

## More Information

- MADR: <https://adr.github.io/madr/>
- The full reasoning is agent-kit's own ADR-0000. This record was set up by
  its `devp-decision-records` skill.
