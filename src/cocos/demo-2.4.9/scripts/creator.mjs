import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

export function creatorPath() {
  const executable = process.env.COCOS_CREATOR || '/Applications/Cocos/Creator/2.4.9/CocosCreator.app/Contents/MacOS/CocosCreator';
  if (!existsSync(executable)) throw new Error('Set COCOS_CREATOR to the Cocos Creator 2.4.9 executable.');
  if (process.platform === 'darwin') {
    const plist = path.resolve(path.dirname(executable), '../Info.plist');
    if (!existsSync(plist) || !/<key>CFBundleShortVersionString<\/key>\s*<string>2\.4\.9<\/string>/.test(readFileSync(plist, 'utf8'))) {
      throw new Error('This demo requires Cocos Creator 2.4.9.');
    }
  }
  return executable;
}
