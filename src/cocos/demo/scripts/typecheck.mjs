import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
if (!existsSync('temp/tsconfig.cocos.json')) throw new Error('Open this project in Creator 3.8.8 or run npm run build:preview to generate the engine declarations first.');
const result = spawnSync(process.execPath, ['node_modules/typescript/bin/tsc', '--noEmit', '--project', 'tsconfig.json'], { stdio: 'inherit' });
process.exit(result.status ?? 1);
