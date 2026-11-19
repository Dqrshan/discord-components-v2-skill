---
name: discord-components-v2
description: Design and build polished Discord bot messages with Components V2 and discord.js (v14.19+). Use for Containers, Sections, TextDisplays, interactive controls, media, embed migrations, and messages where hierarchy, readability, interaction feedback, or visual craft matter.
---

# Discord Components V2 (discord.js)

Use **Components V2** for new message layouts when the message benefits from structured composition or interactive content. Classic messages remain appropriate when the feature set requires them. Treat each message as a compact interface: make its purpose legible immediately, make the next action obvious, and keep the visual structure calm enough to scan in a busy channel.

**Requires discord.js ≥ 14.19** (current latest is 14.28.x). Always set the flag.

## Critical Rules

- Every V2 message **must** include `flags: MessageFlags.IsComponentsV2` (or `MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral`).
- Once a message is sent with the V2 flag, you **cannot** remove it on edit.
- With the flag set you **cannot** send `content`, `embeds`, `poll`, or `stickers`. All visible text lives in `TextDisplayBuilder`.
- Max **40** components total (nested count). Max **4000** characters across all TextDisplays.
- Attachments are invisible unless referenced by a Thumbnail, MediaGallery, or File component via `attachment://filename`.
- Top-level components can be: Container, TextDisplay, Section, Separator, MediaGallery, File, ActionRow.
- Containers cannot nest inside other Containers.
- Every Section needs exactly one accessory (thumbnail or button).

## Limits

| Constraint | Limit | Notes |
| --- | --- | --- |
| Components per message | **40** | Nested components count individually. |
| Text characters | **4,000** | Sum of every `TextDisplay` in the message. |
| Buttons per ActionRow | **5** | Or one select menu, never both in the same row. |
| Select options | **25** | Per select menu. |
| MediaGallery items | **10** | Per gallery. |
| Containers | No nesting | A Container cannot contain another Container. |
| Sections | 1 accessory each | Thumbnail *or* button, not both, not neither. |
| Attachments | 10 per message | Each must be referenced to be visible. |

The classic "5 ActionRows per message" cap is replaced by the 40-component budget when the V2 flag is set — an ActionRow is simply one of the 40 components.

## Imports (typical)

```js
const {
  ContainerBuilder,
  TextDisplayBuilder,
  SectionBuilder,
  SeparatorBuilder,
  SeparatorSpacingSize,
  MediaGalleryBuilder,
  MediaGalleryItemBuilder,
  FileBuilder,
  ThumbnailBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  StringSelectMenuBuilder,
  UserSelectMenuBuilder,
  RoleSelectMenuBuilder,
  ChannelSelectMenuBuilder,
  MentionableSelectMenuBuilder,
  MessageFlags,
  AttachmentBuilder,
} = require('discord.js');
```

## Flags

```js
MessageFlags.IsComponentsV2                          // required for V2 rendering
MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral // ephemeral reply
MessageFlags.IsComponentsV2 | MessageFlags.SuppressEmbeds
```

The flag is required to render V2 components and is **permanent**: once a message is sent with it, editing cannot remove it.

## Core Builders & Patterns

### 1. TextDisplay – all text lives here

```js
new TextDisplayBuilder().setContent('## Heading\nSupports **markdown**, *italics*, `code`, lists, mentions, emojis.')
```

Standard Discord markdown only: headings (`#`–`###`), bold, italic, underline, strikethrough, inline code, code blocks, spoilers (`||text||`), lists, block quotes, links, timestamps, mentions, and emoji.

There is no `content` field on the message when using V2 — this builder is the only place text renders. Prefer multiple small TextDisplays over one giant block for better visual rhythm.

### 2. Container – the modern “embed”

```js
const container = new ContainerBuilder()
  .setAccentColor(0x5865F2)          // optional left accent (hex number)
  // .setSpoiler(true)               // blurs entire container
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent('# Title\nSubtitle or description.'),
  )
  .addSeparatorComponents(
    new SeparatorBuilder().setDivider(true).setSpacing(SeparatorSpacingSize.Small),
  )
  .addActionRowComponents(
    new ActionRowBuilder().addComponents(/* buttons or one select */),
  );
```

Full method set: `addTextDisplayComponents`, `addSectionComponents`, `addSeparatorComponents`, `addActionRowComponents`, `addMediaGalleryComponents`, `addFileComponents`, `addComponents`, and `setComponents([...])` to replace all children. Child order is preserved, so build top-to-bottom in reading order.

Accent colors that look good: Discord blurple `0x5865F2`, success `0x57F287`, danger `0xED4245`, soft gray `0x99AAB5`, or brand colors. Omit accent for a clean flat look. The color must be a number — `'#5865F2'` and `'blurple'` throw.

### 3. Section – text + accessory (thumbnail or button)

```js
new SectionBuilder()
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent('**Feature name**'),
    new TextDisplayBuilder().setContent('Short supporting text. Keep it to 1–3 TextDisplays.'),
  )
  .setThumbnailAccessory(
    new ThumbnailBuilder()
      .setURL('https://example.com/icon.png')   // or attachment://file.png
      .setDescription('Alt text'),
  )
  // OR
  .setButtonAccessory(
    new ButtonBuilder()
      .setCustomId('action')
      .setLabel('Do it')
      .setStyle(ButtonStyle.Primary),
  );
```

Use Sections when you want a thumbnail or a single prominent button beside related text. Never leave a Section without an accessory, and never set both.

### 4. Separator – visual breathing room

```js
new SeparatorBuilder()
  .setDivider(true)                    // show the thin line
  .setSpacing(SeparatorSpacingSize.Small); // or Large
```

Place between logical groups. Prefer Small + divider for most cards; Large for bigger visual breaks. `divider: false` with Large spacing gives a blank gap without a line.

### 5. MediaGallery & File

```js
new MediaGalleryBuilder().addItems(
  new MediaGalleryItemBuilder()
    .setURL('https://…')          // or attachment://image.png
    .setDescription('Alt')
    .setSpoiler(false),
  // up to 10 items
);

new FileBuilder().setURL('attachment://report.pdf'); // must also pass the file in `files`
```

Files uploaded but never referenced by a File, Thumbnail, or MediaGallery stay invisible.

### 6. Thumbnail

```js
new ThumbnailBuilder()
  .setURL('https://…/icon.png')   // or attachment://icon.png
  .setDescription('Alt text')
  .setSpoiler(false);
```

Thumbnails only exist as a Section accessory — they are not top-level components.

### 7. Interactive components (inside ActionRows)

- Max 5 buttons **or** 1 select menu per ActionRow.
- Buttons: `ButtonStyle.Primary | Secondary | Success | Danger | Link | Premium`.
- Link buttons need `.setURL()`, never a customId. Premium buttons need `.setSKUId()`.
- Always give interactive components a unique, namespaced `customId` (e.g. `ticket:close`, `poll:vote:yes`). Custom IDs are max 100 characters.

```js
new ActionRowBuilder().addComponents(
  new ButtonBuilder().setCustomId('confirm').setLabel('Confirm').setStyle(ButtonStyle.Success),
  new ButtonBuilder().setCustomId('cancel').setLabel('Cancel').setStyle(ButtonStyle.Secondary),
);

new ActionRowBuilder().addComponents(
  new StringSelectMenuBuilder()
    .setCustomId('choose-plan')
    .setPlaceholder('Select a plan…')
    .addOptions(
      { label: 'Starter', value: 'starter', description: 'For individuals' },
      { label: 'Pro', value: 'pro', description: 'For teams', emoji: '⭐' },
    ),
);
```

Entity selects share `setCustomId`, `setPlaceholder`, `setMinValues`, `setMaxValues`, `setDisabled`:

| Builder | Default-value setter |
| --- | --- |
| `UserSelectMenuBuilder` | `setDefaultUsers(...)` |
| `RoleSelectMenuBuilder` | `setDefaultRoles(...)` |
| `ChannelSelectMenuBuilder` | `setDefaultChannels(...)`, `setChannelTypes(...)` |
| `MentionableSelectMenuBuilder` | `setDefaultValues(...)` |

Selects have no label of their own inside an ActionRow — the placeholder is what users see.

## Design Engineering for Discord

Apply the same craft discipline used for product interfaces, while respecting an important boundary: Discord owns the rendering and motion of its native components. A bot controls composition, copy, order, colors, media, and state transitions through message updates; it does not control CSS, hover animation, focus rings, tooltip timing, or native button press behavior. Do not promise or simulate browser-style interaction polish where the platform does not expose it.

### Start with the user’s task

Before choosing builders, write down the message’s job in one sentence. A status panel answers “what is happening and what can I do?” A confirmation asks “is this the action I intend?” An announcement tells “what changed, when, and where do I go next?” Build the hierarchy around that job instead of selecting components because they are available.

Use this reading order as a default, not a rigid template:

1. **Orientation** — a concise title or status that identifies the subject.
2. **Meaning** — the essential context, result, or consequence.
3. **Choice** — one clear primary action, with secondary actions kept visually secondary.
4. **Detail** — optional metadata, caveats, or timestamps in a quieter position.

If the user can understand the message from the first two lines, the hierarchy is doing its job. If every line is bold, every button is primary, or every block has a separator, nothing is emphasized.

### Choose a composition that matches the content

| Content shape | Strong default | Why |
| --- | --- | --- |
| One fact or short response | One TextDisplay, optionally inside a Container | Avoids a frame around content that does not need one |
| A grouped card with a few content blocks | One Container with TextDisplays and deliberate separators | Keeps related content visually together |
| A named item with a thumbnail or one contextual action | Section | Pairs the accessory with the text it belongs to |
| Several images that matter equally | MediaGallery | Lets media carry the message without fake columns |
| A task with multiple choices | ActionRow with a small, ordered set of buttons or one select | Keeps controls close to their explanation |
| Long instructions, many records, or dense data | Multiple messages or a focused follow-up flow | Avoids turning one message into a miniature application |

Use a Container when grouping has meaning, not as a decorative border around every message. Containers cannot nest. If a layout needs several independent cards, consider separate top-level Containers only when each card can stand alone and the sequence remains easy to scan.

### Build hierarchy with Discord’s actual tools

- Use one clear `#` title for a message’s primary subject. Use `##` and `###` sparingly to label meaningful subsections; do not use heading levels just to make ordinary sentences larger.
- Put a heading and its short supporting description in the same TextDisplay when they form one thought. Split TextDisplays when the content changes role or the split improves reading order, not to manufacture spacing.
- Use bold for labels and decisive phrases, not whole paragraphs. Use inline code for literal IDs, commands, and values. Use `-#` for genuinely secondary metadata, not important instructions or legal caveats.
- Use bullets for parallel items and numbered lists for sequence. Keep each item short enough to scan on a narrow mobile screen.
- Avoid ASCII tables, fake columns, repeated emoji bullets, and elaborate box-drawing characters. Discord clients and screen sizes vary; rely on component structure and simple markdown.
- Use a Section only when the accessory is meaningfully attached to its text. Keep its text concise because the accessory takes space, especially on mobile. Every Section must have exactly one accessory.

### Use spacing and color as signals

Separators are structural punctuation. Add a divider when the reader benefits from seeing a boundary between distinct groups. Use spacing without a divider when the content needs a pause but not a hard split. Omit both when heading, paragraph, or component boundaries already make the structure clear. Repeated separators create a form-like stack and spend component budget without adding meaning.

Use an accent color only when it reinforces the message’s meaning or the bot’s established identity. Pick one accent for a Container and apply it consistently across related messages. Do not rely on color alone to convey success, warning, or failure: state the meaning in words and use a matching title or icon if useful. Treat example hex values as starting points; check contrast against Discord’s light and dark themes and do not assume a custom color will look identical on every client.

Button styles communicate priority and consequence:

- **Primary** — the one main next step.
- **Secondary** — safe alternatives, navigation, or low-priority controls.
- **Success** — a positive commitment such as accepting or confirming, when the action really is affirmative.
- **Danger** — destructive or hard-to-reverse actions. Pair with explicit consequence text and put it after the safe exit action.
- **Link** — navigation to a destination; label it with the destination or outcome.
- **Premium** — Discord’s SKU purchase flow; use only when that is the intended transaction.

Avoid presenting several equally loud buttons unless the user is making a genuinely balanced choice. Do not use success/danger colors as decoration.

### Write for scanning, trust, and small screens

- Lead with the outcome, not implementation detail. “Your role was updated” is more useful than “Request completed.”
- Put the consequence before a destructive control. Name the affected object and scale where possible: “Delete 47 messages?” rather than “Are you sure?”
- Keep controls and the text that explains them in the same message. Make button labels verb-first and specific: “Open settings”, “Retry upload”, “Delete 47 messages”. Avoid vague labels such as “Click here”, “Okay”, or “Submit” when a more meaningful label fits.
- Keep labels concise, but do not abbreviate so aggressively that users must guess. If two actions sound alike, clarify the outcome in the label or supporting text.
- Put timestamps in Discord’s timestamp syntax (`<t:UNIX:F>` or `<t:UNIX:R>`) when local time conversion or relative time helps. Include a timezone in plain language when a fixed schedule is important.
- Avoid walls of text. Break long help into task-oriented steps, or use a select / button to reveal the relevant detail. Do not force users to parse a large panel to find one common action.
- Budget for mobile: short headings, short paragraphs, few controls per row, and no information whose meaning depends on side-by-side alignment.

### Interaction states are part of the design

An interactive message is not finished when its initial payload looks good. Plan what users see before and after each action:

| State | Design question | Good response |
| --- | --- | --- |
| Ready | Is it clear what each control will do? | Action labels and nearby copy explain the outcome |
| Working | Can the operation take long enough that silence feels broken? | Acknowledge promptly with `deferReply()` or `deferUpdate()`, then edit with the result |
| Success | What changed, and what can happen next? | Confirm the concrete outcome; preserve useful context or provide a next action |
| Failure | Can the user understand and recover? | Explain the issue in plain language and offer a safe retry or route forward |
| Stale | Could the panel no longer match current server state? | Refresh from authoritative data and explain if the requested action is no longer available |
| Disabled / unavailable | Why can’t the user act? | Explain the condition in nearby text; do not make a disabled control carry the only explanation |

Update an existing message when the interaction is a direct continuation of that panel. Use an ephemeral reply for private feedback, validation details, or user-specific outcomes. Do not silently replace a public shared panel with private state if other viewers still need the public context. Disable or remove controls after one-shot actions when repeated clicks would duplicate work. For concurrent users, check permissions and current state in the handler; the rendered button is not authorization.

Give every custom ID a stable namespace and enough context to route it safely, such as `ticket:close:1234`. Keep IDs within Discord’s 100-character limit, avoid embedding secrets or sensitive user data, and validate ownership / permissions in the handler. A custom ID is routing data, not proof that the caller may perform the action.

### Accessibility and media

- Give meaningful images useful descriptions. Describe what the image contributes, not “image” or “picture”. Use an empty / omitted description only where the image is purely decorative and the API supports that choice.
- Never put essential instructions, a code, or an action only inside an image. Repeat essential context in text.
- Use emoji sparingly and consistently. Emoji can help identify familiar status, but they render differently across platforms and are not a substitute for labels.
- Make links understandable out of context. Prefer `[View the incident report](…)` or a descriptive Link button over a raw URL or “here”.
- Do not use color, position, or emoji alone to communicate an error or state. Include a word label such as “Failed”, “Waiting”, or “Complete”.
- Respect spoilers for sensitive media and use them intentionally; spoiler treatment does not replace a text warning when context matters.

### Motion, feedback, and perceived speed

Discord controls native hover, focus, press, and component-opening motion. Do not add advice about CSS transitions, spring curves, `:active` transforms, tooltip timing, or popover origins to Discord message recipes: bot-authored messages cannot set those properties. The relevant design-engineering principle is to make the system acknowledge input quickly and predictably.

- Acknowledge interactions before slow network or database work. Discord requires an initial interaction response within its response window; defer promptly when work will exceed a quick handler.
- Prefer a concise state update over decorative message churn. Do not animate by repeatedly editing a message unless progress is meaningful and the user benefits from it.
- Keep repeated controls stable. A refresh button should not reorder the whole panel or make users lose their place without a reason.
- For a multi-step operation, show the current step and a safe way to cancel or return when possible. Avoid fake progress percentages when the work cannot report real progress.
- When editing a message, preserve its established hierarchy and component order unless the underlying state changed enough to justify a new layout.

### Component budget is a design constraint

Count the complete payload, including nested components, before adding polish. Keep a small margin below hard limits so optional states, localization, and future actions do not immediately break the message. Repeated rows and separators have a real cost. Track both the 40-component budget and the 4,000-character TextDisplay budget; split a flow when the content no longer fits comfortably, even if it technically fits.

Design for translated copy and dynamic data. Long names, localized labels, large counts, empty results, missing images, and permission errors can all change the composition. Do not assume the sample values are the shortest values. Truncate only when the full value is available through a clear follow-up, and preserve important identifiers.

### 8. Attachments

```js
const file = new AttachmentBuilder(buffer, { name: 'chart.png' });
// reference it as 'attachment://chart.png' in a MediaGallery, Thumbnail, or File
```

The attachment `name` is what `attachment://` must match — including case and extension.

## Sending & Editing

```js
// Channel or interaction
await channel.send({
  components: [container],          // or [text, separator, container, …]
  flags: MessageFlags.IsComponentsV2,
  files: [attachment],              // only if referenced
  allowedMentions: { parse: [] },   // control pings from TextDisplays
});

// Ephemeral
flags: MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral

// Edit (flag is permanent)
await message.edit({
  components: [newLayout],
  // do NOT try to clear the V2 flag
});
```

All builders implement `.toJSON()`. If you persist layouts, store `container.toJSON()` and pass the JSON back into `components` to rebuild.

## Beautiful Layout Recipes

### Clean info card

```js
new ContainerBuilder()
  .setAccentColor(0x5865F2)
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent('# Server Rules\nPlease read carefully.'),
  )
  .addSeparatorComponents(new SeparatorBuilder().setDivider(true).setSpacing(SeparatorSpacingSize.Small))
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent('1. Be respectful\n2. No spam\n3. Follow Discord ToS'),
  )
  .addActionRowComponents(
    new ActionRowBuilder().addComponents(
      new ButtonBuilder().setCustomId('rules:accept').setLabel('I Agree').setStyle(ButtonStyle.Success),
    ),
  );
```

### Feature highlight with thumbnail

```js
new ContainerBuilder()
  .setAccentColor(0x57F287)
  .addSectionComponents(
    new SectionBuilder()
      .addTextDisplayComponents(
        new TextDisplayBuilder().setContent('## New Dashboard'),
        new TextDisplayBuilder().setContent('Real-time stats, role management, and analytics in one place.'),
      )
      .setThumbnailAccessory(new ThumbnailBuilder().setURL('attachment://dashboard.png').setDescription('Dashboard preview')),
  )
  .addActionRowComponents(
    new ActionRowBuilder().addComponents(
      new ButtonBuilder().setCustomId('dashboard:open').setLabel('Open Dashboard').setStyle(ButtonStyle.Primary),
      new ButtonBuilder().setLabel('Changelog').setURL('https://example.com/changelog').setStyle(ButtonStyle.Link),
    ),
  );
```

Pass `files: [new AttachmentBuilder(buffer, { name: 'dashboard.png' })]` alongside the components.

### Multi-section dashboard-style message

```js
new ContainerBuilder()
  .setAccentColor(0x5865F2)
  .addTextDisplayComponents(new TextDisplayBuilder().setContent('# Control Panel'))
  .addSeparatorComponents(new SeparatorBuilder().setDivider(true).setSpacing(SeparatorSpacingSize.Small))
  .addSectionComponents(
    new SectionBuilder()
      .addTextDisplayComponents(
        new TextDisplayBuilder().setContent('**Status**'),
        new TextDisplayBuilder().setContent('🟢 All systems operational\n👥 1,284 members\n📈 42 joins today'),
      )
      .setButtonAccessory(
        new ButtonBuilder().setCustomId('status:refresh').setLabel('Refresh').setStyle(ButtonStyle.Secondary),
      ),
  )
  .addSeparatorComponents(new SeparatorBuilder().setDivider(false).setSpacing(SeparatorSpacingSize.Large))
  .addSectionComponents(
    new SectionBuilder()
      .addTextDisplayComponents(
        new TextDisplayBuilder().setContent('**Actions**'),
        new TextDisplayBuilder().setContent('Moderate, announce, or configure the server.'),
      )
      .setButtonAccessory(
        new ButtonBuilder().setCustomId('panel:settings').setLabel('Settings').setStyle(ButtonStyle.Secondary),
      ),
  )
  .addActionRowComponents(
    new ActionRowBuilder().addComponents(
      new ButtonBuilder().setCustomId('panel:announce').setLabel('Announce').setStyle(ButtonStyle.Primary),
      new ButtonBuilder().setCustomId('panel:moderate').setLabel('Moderate').setStyle(ButtonStyle.Danger),
    ),
  );
```

### Image-led announcement

Keep the text to 2–3 short lines so the image stays the focus. The banner is a MediaGallery item — remember to upload it.

```js
new ContainerBuilder()
  .setAccentColor(0xFEE75C)
  .addMediaGalleryComponents(
    new MediaGalleryBuilder().addItems(
      new MediaGalleryItemBuilder().setURL('attachment://event-banner.png').setDescription('Summer event banner'),
    ),
  )
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent('# Summer Event\nJoin us **Friday at 8 PM** for the launch stream.'),
  )
  .addSeparatorComponents(new SeparatorBuilder().setDivider(true).setSpacing(SeparatorSpacingSize.Small))
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent('-# Participation is optional · Times shown in UTC'),
  );
```

`-#` is subtext — perfect for fine print without competing with the headline.

### Ephemeral confirmation / error

Reuse one helper with an accent + title + message instead of writing two layouts.

```js
const status = (type, text) => new ContainerBuilder()
  .setAccentColor(type === 'error' ? 0xED4245 : 0x57F287)
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent(`### ${type === 'error' ? 'Something went wrong' : 'Done'}\n${text}`),
  );

await interaction.reply({
  components: [status('error', 'You do not have permission to do that.')],
  flags: MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral,
});
```

Keep ephemeral replies to a single Container — no separators, no action rows unless you need a follow-up button.

### Confirmation prompt

Put the destructive action last and style it `Danger`.

```js
new ContainerBuilder()
  .setAccentColor(0xFEE75C)
  .addTextDisplayComponents(
    new TextDisplayBuilder().setContent('## Delete 47 messages?'),
    new TextDisplayBuilder().setContent('This cannot be undone.'),
  )
  .addActionRowComponents(
    new ActionRowBuilder().addComponents(
      new ButtonBuilder().setCustomId('purge:cancel').setLabel('Cancel').setStyle(ButtonStyle.Secondary),
      new ButtonBuilder().setCustomId('purge:confirm').setLabel('Delete').setStyle(ButtonStyle.Danger),
    ),
  );
```

### Compact list

For changelogs, leaderboards, and status lists: bold the label, keep each entry on one line, use `-#` for metadata.

```js
new TextDisplayBuilder().setContent([
  '### Recent Deploys',
  '**v2.4.0** — `main` · 2 hours ago',
  '**v2.3.2** — fix cache invalidation · yesterday',
  '-# Showing the last 2 of 18 deploys',
].join('\n'))
```

## Design Principles for Appealing Messages

1. **Hierarchy** – Start with a clear `#` or `##` title inside a TextDisplay. Use Sections for key features.
2. **Whitespace** – Insert Separators between logical blocks. Prefer Small + divider for most cases; Large without a divider between major regions.
3. **Accent color** – One accent per Container. Match the emotion (blurple = neutral/info, green = success, red = danger, yellow = attention). Two accents in one message reads as a bug.
4. **Scannability** – Short paragraphs, bullet lists, bold key terms. Avoid walls of text.
5. **Action placement** – Primary actions at the bottom in an ActionRow. Secondary actions can live in Section accessories.
6. **Consistency** – Reuse the same accent, separator style, and button styles across a bot’s UI.
7. **Accessibility** – Always set `description` / alt text on thumbnails and media items.
8. **Custom IDs** – Namespace them (`module:action:id`) so interaction handlers stay clean.
9. **Limits awareness** – Count nested components. Prefer a few well-structured Containers over many tiny ones.
10. **No classic embeds** – Do not mix. Convert old embed designs into Container + TextDisplay + Section patterns.

## Migrating From Embeds

| Classic embed field | V2 replacement |
| --- | --- |
| `title` | TextDisplay with `#` or `##` heading |
| `description` | TextDisplay body |
| `fields[]` (inline) | Multiple TextDisplays, or Sections for icon + text |
| `fields[]` (name + value) | `**Name**\ntext` in one TextDisplay per field |
| `color` | `ContainerBuilder.setAccentColor()` |
| `thumbnail` | `SectionBuilder.setThumbnailAccessory()` |
| `image` | `MediaGalleryBuilder` with one item |
| `footer.iconURL` | Thumbnail or emoji in the text |
| `footer.text` | `-# footer text` subtext line |
| `author` | TextDisplay with bold name, avatar gallery if needed |
| `timestamp` | `<t:UNIX:R>` inside the text |
| `url` (title link) | `[Title](url)` markdown |

Two structural differences matter: embeds are flat (V2 is nested, so anything visually grouped becomes one Container), and there is no footer/field chrome (you build it with markdown and separators).

```js
// Before — classic embed
await channel.send({
  embeds: [{
    color: 0x5865F2,
    title: 'Server Rules',
    description: 'Please read carefully.',
    fields: [{ name: '1.', value: 'Be respectful' }, { name: '2.', value: 'No spam' }],
    footer: { text: 'Updated 2026' },
    thumbnail: { url: 'https://example.com/icon.png' },
  }],
  components: [new ActionRowBuilder().addComponents(acceptButton)],
});

// After — Components V2
await channel.send({
  flags: MessageFlags.IsComponentsV2,
  components: [
    new ContainerBuilder()
      .setAccentColor(0x5865F2)
      .addSectionComponents(
        new SectionBuilder()
          .addTextDisplayComponents(
            new TextDisplayBuilder().setContent('# Server Rules'),
            new TextDisplayBuilder().setContent('Please read carefully.'),
          )
          .setThumbnailAccessory(
            new ThumbnailBuilder().setURL('https://example.com/icon.png').setDescription('Server icon'),
          ),
      )
      .addSeparatorComponents(new SeparatorBuilder().setDivider(true).setSpacing(SeparatorSpacingSize.Small))
      .addTextDisplayComponents(
        new TextDisplayBuilder().setContent('**1.** Be respectful\n**2.** No spam'),
        new TextDisplayBuilder().setContent('-# Updated 2026'),
      )
      .addActionRowComponents(new ActionRowBuilder().addComponents(acceptButton)),
  ],
});
```

Keep classic embeds only when you need webhook messages authored by other tools, `poll`, stickers, or compatibility with discord.js < 14.19. Mixing both in one message is not possible.

## Troubleshooting

| Error / symptom | Cause | Fix |
| --- | --- | --- |
| `Invalid Form Body … components.0` | Flag missing, or a top-level type V2 does not allow (e.g. a bare button) | Set `flags: MessageFlags.IsComponentsV2`; wrap buttons in `ActionRowBuilder` |
| `Cannot send content/embeds with Components V2` | `content`, `embeds`, `poll`, or `stickers` in the payload | Delete those fields; move text into `TextDisplayBuilder` |
| Message renders but text is invisible | Text sent via `content` | Move it into a TextDisplay inside a Container |
| Attachment missing from the message | Uploaded but unreferenced | Reference it as `attachment://<name>` in File/Thumbnail/MediaGallery |
| `Invalid string length` / 4000-char error | TextDisplays sum beyond 4,000 chars | Split into multiple messages or shorten |
| `Too many components` | More than 40 nested components | Group into fewer Sections; drop redundant separators |
| Section invalid | Zero or two accessories | Use exactly one of `setThumbnailAccessory` / `setButtonAccessory` |
| `custom_id` error on a button | `Link`/`Premium` button with a customId, or a normal button without one | Link → `setURL`, Premium → `setSKUId`, others → `setCustomId` |
| Edit throws when clearing old components | Trying to remove the V2 flag | You cannot. Send a fresh message instead of downgrading |
| Accent color ignored | Color passed as a string | Pass `0xRRGGBB` number |
| `X is not a constructor` | discord.js < 14.19 | `npm install discord.js@latest`, then `npm ls discord.js` |

## Interaction Handling

Route by custom ID prefix so one listener stays readable. Design the handler to acknowledge promptly, validate permissions and current state on the server, and return a message state that explains what happened.

```js
client.on('interactionCreate', async (interaction) => {
  if (!interaction.isButton() && !interaction.isAnySelectMenu()) return;

  const [module, action, resourceId] = interaction.customId.split(':');

  if (module === 'rules' && action === 'accept') {
    // Validate the user / guild context before applying the change.
    await interaction.reply({
      components: [buildNotice('success', 'Rules accepted', 'You can now access the member channels.')],
      flags: MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral,
    });
    return;
  }

  if (module === 'status' && action === 'refresh') {
    await interaction.deferUpdate();
    try {
      const status = await loadStatus();
      await interaction.editReply({ components: [buildStatusPanel(status)] });
    } catch {
      await interaction.followUp({
        components: [buildNotice('error', 'Could not refresh', 'Please try again in a moment.')],
        flags: MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral,
      });
    }
  }

  if (module === 'ticket' && action === 'close') {
    await interaction.deferReply({ flags: MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral });
    const allowed = await canCloseTicket(interaction.user.id, resourceId);
    if (!allowed) {
      await interaction.editReply({
        components: [buildNotice('error', 'Ticket unchanged', 'You do not have permission to close this ticket.')],
      });
      return;
    }
    await closeTicket(resourceId);
    await interaction.editReply({
      components: [buildNotice('success', 'Ticket closed', 'The conversation is now archived.')],
    });
  }
});
```

- `interaction.update()` keeps the existing flags — do not pass the flag again to "add" it.
- `deferUpdate()` acknowledges a component interaction without showing a loading reply, then `editReply()` updates the source message.
- `deferReply({ flags: MessageFlags.Ephemeral })` is appropriate when the response is private. The defer call sets the response visibility; the follow-up edit should preserve that response rather than trying to change its visibility.
- Ephemeral replies are a **new** message; the original stays public.
- Modals are not V2 — `ModalBuilder` still uses classic components.

The snippet illustrates the flow, not a complete production router. Handle unknown IDs explicitly, make permission checks against current data, and avoid exposing exception details to users. Log diagnostic detail server-side while returning a short recovery-oriented message.

## Quick Checklist Before Sending

- [ ] **Payload:** `MessageFlags.IsComponentsV2` is set; unsupported `content`, `embeds`, `poll`, and `stickers` fields are absent.
- [ ] **Structure:** top-level and nested component types are valid; Containers are not nested; each Section has exactly one accessory.
- [ ] **Budget:** count all nested components and all TextDisplay characters; leave headroom for real data and localization.
- [ ] **Media:** every `attachment://` reference exactly matches an uploaded filename; meaningful images have useful descriptions.
- [ ] **Hierarchy:** the subject and outcome are clear in the first lines; separators and accents mark real structure.
- [ ] **Actions:** the primary action is obvious; labels describe outcomes; destructive actions explain consequences and have a safe exit.
- [ ] **State:** slow actions are acknowledged; handlers validate permissions and current state; success and failure states help users recover.
- [ ] **Mobile:** labels, paragraphs, and lists remain understandable without side-by-side alignment or long unbroken strings.
- [ ] **Safety:** mentions are controlled with `allowedMentions` where user supplied or generated text could unexpectedly ping; custom IDs contain no secrets.
- [ ] **Edit path:** the V2 flag's permanence is understood before sending; later edits keep the message in the V2 format.

When asked for a “pretty”, “modern”, “clean”, or “beautiful” Discord message, first choose the simplest composition that fits the task. Use a Container when grouping helps, clear hierarchy in TextDisplays, Sections only for meaningful accessories, purposeful separators, restrained accent color, and a specific primary action. Beauty here comes from clarity, consistency, and reliable state changes—not from filling every available slot.
