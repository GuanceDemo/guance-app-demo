/** Retain Creator's engine startup while moving its window into the UIKit scene. */
export function adoptIosScenes(source) {
  if (source.includes('// DEMO_UIKIT_SCENE_LIFECYCLE')) return applyControlsOrientation(source);
  const implementation = source.match(/@implementation\s+(\w+)/)?.[1];
  const launch = /-\s*\(BOOL\)application:\(UIApplication\s*\*\)\s*(\w+)\s+didFinishLaunchingWithOptions:\(NSDictionary\s*\*\)\s*(\w+)\s*\{/.exec(source);
  if (!implementation || !launch) throw new Error('Missing Creator iOS application delegate for scene migration.');
  const open = launch.index + launch[0].length - 1;
  let end = open + 1, depth = 1;
  for (; end < source.length && depth; end++) {
    if (source[end] === '{') depth++;
    if (source[end] === '}') depth--;
  }
  if (depth) throw new Error('Unterminated Creator launch callback.');
  let body = source.slice(open + 1, end - 1);
  if (!/return YES;\s*$/.test(body)) throw new Error('Unknown Creator launch result.');
  const processStartup = [];
  body = body.replace(/\[GCNativeTelemetry boot\];|\[\[SDKWrapper[^\n;]+didFinishLaunchingWithOptions:[^\n;]+;/g, call => {
    processStartup.push(call); return '';
  });
  body = body.replace(/\[\[UIScreen mainScreen\] bounds\]/g, 'scene.coordinateSpace.bounds')
    .replace(/\[\[UIScreen mainScreen\] scale\]|UIScreen\.mainScreen\.scale/g, 'scene.screen.scale');
  if (!/\[\[UIWindow alloc\] initWithFrame:\s*\w+\]/.test(body)) throw new Error('Missing Creator window creation.');
  body = body.replace(/\[\[UIWindow alloc\] initWithFrame:\s*\w+\]/, '[[UIWindow alloc] initWithWindowScene:scene]')
    .replace(/return YES;\s*$/, '');
  const [, application, options] = launch;
  const migrated = `${launch[0]}
    self.gcLaunchOptions = ${options};
    ${processStartup.join('\n    ')}
    return YES;
}

- (void)gcConnectWindowScene:(UIWindowScene *)scene {
    // Creator owns one engine. Reconnecting a scene reuses its existing window.
    if (self.window) {
        self.window.windowScene = scene;
        [self.window makeKeyAndVisible];
        return;
    }
    UIApplication *${application} = UIApplication.sharedApplication;
    NSDictionary *${options} = self.gcLaunchOptions;
${body}
}`;
  source = source.slice(0, launch.index) + migrated + source.slice(end);
  source = source.replace(`@implementation ${implementation}`, `// DEMO_UIKIT_SCENE_LIFECYCLE
@interface ${implementation} () <GCSceneHost>
@property(nonatomic, copy) NSDictionary *gcLaunchOptions;
@end

@implementation ${implementation}`);
  return applyControlsOrientation('#import "GCSceneDelegate.h"\n' + source);
}

export function addIosSceneManifest(source) {
  if (source.includes('<key>UIApplicationSceneManifest</key>')) return source;
  return source.replace('<dict>', `<dict>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key><false/>
        <key>UISceneConfigurations</key>
        <dict>
            <key>UIWindowSceneSessionRoleApplication</key>
            <array><dict>
                <key>UISceneConfigurationName</key><string>Cocos</string>
                <key>UISceneDelegateClassName</key><string>GCSceneDelegate</string>
            </dict></array>
        </dict>
    </dict>`);
}

export function useSceneApplication(source) {
  if (source.includes('@"GCCocosApplication"')) return source;
  const entry = /(UIApplicationMain\(argc,\s*(?:\(char\*\*\))?argv,\s*)nil,/;
  if (!entry.test(source)) throw new Error('Missing Creator UIApplicationMain entry point.');
  return source.replace(entry, '$1@"GCCocosApplication",');
}

/** Retained native projects must pick up the same rotation support as fresh builds. */
export function enableIosRotation(source) {
  const orientations = '<array><string>UIInterfaceOrientationPortrait</string><string>UIInterfaceOrientationLandscapeLeft</string><string>UIInterfaceOrientationLandscapeRight</string></array>';
  const supported = /(<key>UISupportedInterfaceOrientations(?:~iphone|~ipad)?<\/key>\s*)<array>[\s\S]*?<\/array>/g;
  source = source.replace(supported, (_, key) => key + orientations);
  if (!source.includes('<key>UISupportedInterfaceOrientations</key>')) {
    source = source.replace('<dict>', '<dict>\n<key>UISupportedInterfaceOrientations</key>' + orientations);
  }
  return source;
}

/** The app stays portrait until a concrete Controls fixture opts into rotation. */
function applyControlsOrientation(source) {
  if (source.includes('// DEMO_CONTROLS_ORIENTATION')) return source;
  const end=source.lastIndexOf('@end');
  return source.slice(0,end)+`// DEMO_CONTROLS_ORIENTATION
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [GCSceneDelegate controlsOrientationMask];
}
`+source.slice(end);
}
