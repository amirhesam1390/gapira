#!/usr/bin/env bash
set -euo pipefail
JL="TMessagesProj/lib/jlatexmath/jlatexmath"
if [ ! -d "$JL/.git" ]; then
  echo "cloning jlatexmath..."
  rm -rf "$JL"
  mkdir -p "$(dirname "$JL")"
  git clone --depth=1 https://github.com/dkaraush/jlatexmath-android.git "$JL"
fi
cat > "$JL/build.gradle" <<'GRADLE'
allprojects {
    repositories { google(); mavenCentral() }
    version = "1.0.0"
    group = "ru.noties.jlatexmath"
}
ext {
    config = [ 'min-sdk':21, 'target-sdk':36, 'build-tools':'36.0.0' ]
    deps = [ 'x-annotations':'androidx.annotation:annotation:1.7.0' ]
    registerArtifact = { project -> }
}
GRADLE
cat > "$JL/jlatexmath/build.gradle" <<'GRADLE'
apply plugin: 'com.android.library'
android {
    namespace 'ru.noties.jlatexmath.android'
    compileSdk 36
    buildToolsVersion '36.0.0'
    defaultConfig { minSdk 21 }
    sourceSets { test.java.srcDirs = [] }
    lint { abortOnError false }
}
repositories { google(); mavenCentral() }
dependencies { api 'androidx.annotation:annotation:1.7.0' }
GRADLE
for mod in jlatexmath-font-cyrillic jlatexmath-font-greek; do
  mkdir -p "$JL/$mod"
  cat > "$JL/$mod/build.gradle" <<'GRADLE'
apply plugin: 'com.android.library'
android {
    namespace 'ru.noties.jlatexmath.font'
    compileSdk 36
    buildToolsVersion '36.0.0'
    defaultConfig { minSdk 21 }
}
repositories { google(); mavenCentral() }
GRADLE
done
cat > "$JL/settings.gradle" <<'GRADLE'
rootProject.name = 'jlatexmath-parent'
include ':jlatexmath'
include ':jlatexmath-font-cyrillic'
include ':jlatexmath-font-greek'
GRADLE
if ! grep -q "jlatexmath/jlatexmath/jlatexmath'" settings.gradle; then
  sed -i "s#project(':jlatexmath').projectDir = file('TMessagesProj/lib/jlatexmath/jlatexmath')#project(':jlatexmath').projectDir = file('TMessagesProj/lib/jlatexmath/jlatexmath/jlatexmath')#" settings.gradle || echo "!! sed settings.gradle failed"
fi
echo "jlatexmath patched successfully"
grep -n "jlatexmath" settings.gradle || true
grep -E "namespace|com.android.library" "$JL/jlatexmath/build.gradle" || true
