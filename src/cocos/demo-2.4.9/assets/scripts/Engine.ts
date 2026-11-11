/** Creator 2.4 uses the global cc/jsb APIs. Keep all engine imports local. */
export import Node = cc.Node;
export import Color = cc.Color;
export import Component = cc.Component;
export import Camera = cc.Camera;
export import Canvas = cc.Canvas;
export import Label = cc.Label;
export import Button = cc.Button;
export import EditBox = cc.EditBox;
export import Graphics = cc.Graphics;
export import Mask = cc.Mask;
export import ScrollView = cc.ScrollView;
export import ViewGroup = cc.ViewGroup;
export import Sprite = cc.Sprite;
export import SpriteFrame = cc.SpriteFrame;
export import Texture2D = cc.Texture2D;
export import Vec2 = cc.Vec2;
export import Vec3 = cc.Vec3;
export import EventTouch = cc.Event.EventTouch;
export const { _decorator, assetManager, director, game, sys, view, tween, macro, isValid, ResolutionPolicy } = cc;
export const Game = cc.game;
export const profiler = { hideStats: () => cc.debug.setDisplayStats(false) };
// jsb is available only in native builds. Resolve it lazily for browser preview.
export const native = { reflection: { callStaticMethod(...args: unknown[]): unknown {
  return (jsb.reflection.callStaticMethod as (...values: unknown[]) => unknown)(...args);
} } };
