export type CoverageCategory = 'ui' | '3d' | 'diagnostics';
export type CoverageKind = 'basic' | 'input' | 'scroll' | 'layout' | 'effects' | 'motion' | 'assets' | 'webview'
  | 'render' | 'perspective' | 'lights' | 'geometry' | 'rig' | 'postprocess' | 'native' | 'evidence' | 'version-diff' | 'support' | 'optional';

export interface CoverageEntry {
  id: CoverageKind;
  category: CoverageCategory;
  title: string;
  description: string;
  generation?: 2 | 3;
}

export const coverageCategories: ReadonlyArray<{ id: CoverageCategory; title: string }> = [
  { id: 'ui', title: 'UI components' },
  { id: '3d', title: '3D components' },
  { id: 'diagnostics', title: 'Physics and feature support' },
];

// Matches the component/3D/diagnostic entries in ft-sdk-cocos's Hybrid samples.
export const coverageEntries: ReadonlyArray<CoverageEntry> = [
  { id: 'basic', category: 'ui', title: 'Basic controls', description: 'Label, RichText, Sprite, Button and Toggle' },
  { id: 'input', category: 'ui', title: 'Inputs', description: 'Normal, password, sensitive and dynamic EditBox' },
  { id: 'scroll', category: 'ui', title: 'Scroll views', description: 'Slider, ProgressBar, ScrollView, ScrollBar and Mask' },
  { id: 'layout', category: 'ui', title: 'Layout and pages', description: 'PageView, indicator, ToggleContainer, Layout and Widget' },
  { id: 'effects', category: 'ui', title: 'Visual effects', description: 'Graphics, label effects, VideoPlayer and WebView' },
  { id: 'motion', category: 'ui', title: 'Motion', description: 'Animation, particles, trails, opacity and SafeArea' },
  { id: 'assets', category: 'ui', title: 'Tile and skeleton assets', description: 'TiledMap, TiledTile, Spine, DragonBones and SubContextView' },
  { id: 'webview', category: 'ui', title: 'WebView', description: 'Load and reload the configured Demo API URL' },
  { id: 'render', category: 'ui', title: 'UI rendering', description: 'UIOpacity, UIMeshRenderer, SpriteRenderer and transforms', generation: 3 },
  { id: 'native', category: '3d', title: '3D components', description: 'Meshes, lights, particles, skeleton and skinned meshes', generation: 2 },
  { id: 'perspective', category: '3d', title: 'Perspective scene', description: 'Moving meshes, camera depth and occlusion', generation: 3 },
  { id: 'lights', category: '3d', title: 'Mesh and lights', description: 'Directional, point, sphere and spot lights', generation: 3 },
  { id: 'geometry', category: '3d', title: 'Geometry', description: 'LODGroup, Billboard, Line, particles and ReflectionProbe', generation: 3 },
  { id: 'rig', category: '3d', title: 'Skinning and terrain', description: 'Skeletal animation, skinning, batches, graph and Terrain', generation: 3 },
  { id: 'postprocess', category: '3d', title: 'Post effects', description: 'Real post-processing controls and capture comparison', generation: 3 },
  { id: 'evidence', category: 'diagnostics', title: 'Physics and support components', description: 'Colliders, rigid bodies, joints, audio and input blocking' },
  { id: 'version-diff', category: 'diagnostics', title: 'Creator 2.4.x differences', description: 'Version-specific text, sprites, particles and SafeArea', generation: 2 },
  { id: 'support', category: 'diagnostics', title: 'Feature support', description: 'Probe the installed engine components', generation: 3 },
  { id: 'optional', category: 'diagnostics', title: 'Optional modules', description: 'Sorting and optional component availability', generation: 3 },
];

export function coverageFor(generation: 2 | 3, category?: CoverageCategory): ReadonlyArray<CoverageEntry> {
  return coverageEntries.filter(entry => (!entry.generation || entry.generation === generation)
    && (!category || entry.category === category));
}
