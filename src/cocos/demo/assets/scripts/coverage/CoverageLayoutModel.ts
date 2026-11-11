export interface Area { x: number; y: number; width: number; height: number }
export interface CoverageViewport { width: number; height: number; portrait: boolean }
export interface CoverageRegions { viewport: CoverageViewport; header: Area; body: Area; commands: Area; status: Area; navigation: Area }

/** Match the physical aspect ratio, using one uniform scale and no letterboxing. */
export function coverageViewport(width: number, height: number): CoverageViewport {
  if (!(width > 0 && height > 0)) return { width: 720, height: 1280, portrait: true };
  const scale = 720 / Math.min(width, height);
  return { width: width * scale, height: height * scale, portrait: height >= width };
}

export function coverageRegions(viewport: CoverageViewport, safe: Area, commandCount: number): CoverageRegions {
  const gap = 16, width = Math.max(1, safe.width - 32);
  const left = safe.x - viewport.width / 2 + gap;
  const top = safe.y + safe.height - viewport.height / 2 - gap;
  const bottom = safe.y - viewport.height / 2 + gap;
  const navigation = { x: left + width / 2, y: bottom + 38, width, height: 76 };
  const header = { x: left + width / 2, y: top - 52, width, height: 104 };
  const bodyTop = top - header.height - gap;
  const lower = bottom + navigation.height + gap;
  if (viewport.portrait) {
    const commandHeight = commandCount ? Math.ceil(commandCount / 2) * 76 - 12 : 0;
    const commands = { x: left + width / 2, y: lower + commandHeight / 2, width, height: commandHeight };
    const status = { x: left + width / 2, y: lower + commandHeight + 32, width, height: 40 };
    const bodyBottom = lower + commandHeight + (commandCount ? 64 : 0);
    return { viewport, header, navigation, commands, status,
      body: { x: left + width / 2, y: (bodyTop + bodyBottom) / 2, width, height: Math.max(80, bodyTop - bodyBottom) } };
  }
  const railWidth = commandCount ? Math.min(400, width * 0.32) : 0;
  const railLeft = left + width - railWidth;
  const commands = { x: railLeft + railWidth / 2, y: lower + (bodyTop - lower) / 2, width: railWidth, height: bodyTop - lower - 84 };
  commands.y -= 42;
  const status = { x: commands.x, y: bodyTop - 32, width: railWidth || width, height: 64 };
  const bodyWidth = width - (railWidth ? railWidth + gap : 0);
  return { viewport, header, navigation, commands, status,
    body: { x: left + bodyWidth / 2, y: (bodyTop + lower) / 2, width: bodyWidth, height: Math.max(80, bodyTop - lower) } };
}

export function commandAreas(area: Area, count: number): Area[] {
  if (!count) return [];
  const columns = 2, rows = Math.ceil(count / columns), gap = 12;
  const width = (area.width - gap) / columns;
  const height = Math.min(76, (area.height - gap * (rows - 1)) / rows);
  return Array.from({length:count}, (_, i) => ({
    x: area.x - area.width / 2 + width / 2 + (i % columns) * (width + gap),
    y: area.y + area.height / 2 - height / 2 - Math.floor(i / columns) * (height + gap), width, height,
  }));
}
