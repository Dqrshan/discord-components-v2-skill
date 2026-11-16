---
name: discord-components-v2
description: Create beautiful Discord bot messages using Components V2 with discord.js (v14.19+). Use when building or refactoring Discord bots that need modern layouts, containers, sections, text displays, buttons, select menus, media galleries, or when the user mentions Components V2, display components, IS_COMPONENTS_V2, or wants polished interactive messages without classic embeds.
---

# Discord Components V2 (discord.js)

Use **Components V2** for all new message layouts. Classic `content` + `embeds` + action rows still work, but V2 gives full layout control and is the recommended modern approach.

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

Route by custom ID prefix so one listener stays readable.

```js
client.on('interactionCreate', async (interaction) => {
  if (!interaction.isButton() && !interaction.isAnySelectMenu()) return;

  const [module, action] = interaction.customId.split(':');

  if (module === 'rules' && action === 'accept') {
    await interaction.reply({
      components: [/* success container */],
      flags: MessageFlags.IsComponentsV2 | MessageFlags.Ephemeral,
    });
    return;
  }

  if (module === 'status' && action === 'refresh') {
    await interaction.update({ components: [buildStatusPanel()] }); // keeps the flag, swaps the layout
  }
});
```

- `interaction.update()` keeps the existing flags — do not pass the flag again to "add" it.
- Ephemeral replies are a **new** message; the original stays public.
- Modals are not V2 — `ModalBuilder` still uses classic components.

## Quick Checklist Before Sending

- [ ] `MessageFlags.IsComponentsV2` present
- [ ] No `content` / `embeds` / `poll` / `stickers`
- [ ] Every Section has exactly one accessory
- [ ] Every `attachment://` filename matches a file in `files`
- [ ] Total components ≤ 40, text ≤ 4000 chars
- [ ] Buttons/selects have proper customIds or URLs
- [ ] Accent color is a number (0xRRGGBB), not a string
- [ ] Message looks scannable and has visual breathing room

When the user asks for a “pretty”, “modern”, “clean”, or “beautiful” Discord message, default to Components V2 Containers with good hierarchy, separators, and restrained accent colors.
