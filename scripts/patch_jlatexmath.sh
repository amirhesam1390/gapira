#!/usr/bin/env bash
set -euo pipefail

JL="TMessagesProj/lib/jlatexmath/jlatexmath"

if [ ! -d "$JL/.git" ]; then
  echo "cloning jlatexmath..."
  rm -rf "$JL"
  mkdir -p "$(dirname "$JL")"
  git clone --depth=1 https://github.com/dkaraush/jlatexmath-android.git "$JL"
fi

# root build.gradle (no buildscript, uses parent's AGP)
cat > "$JL/build.gradle" <<'GRADLE'
allprojects {
    repositories {
        google()
        mavenCentral()
    }
    version = "1.0.0"
    group = "ru.noties.jlatexmath"
}
ext {
    config = [
            'min-sdk'    : 21,
            'target-sdk' : 36,
            'build-tools': '36.0.0',
    ]
    deps = [
            'x-annotations': 'androidx.annotation:annotation:1.7.0',
    ]
    registerArtifact = { project -> }
}
GRADLE

# jlatexmath module — missingDimensionStrategy is the key fix
cat > "$JL/jlatexmath/build.gradle" <<'GRADLE'
apply plugin: 'com.android.library'

android {
    namespace 'ru.noties.jlatexmath.android'
    compileSdk 36
    buildToolsVersion '36.0.0'

    defaultConfig {
        minSdk 21
        missingDimensionStrategy 'minApi', 'afat'
    }

    sourceSets { test.java.srcDirs = [] }
    lint { abortOnError false }
}

repositories { google(); mavenCentral() }
dependencies { api 'androidx.annotation:annotation:1.7.0' }
GRADLE

# font modules
for mod in jlatexmath-font-cyrillic jlatexmath-font-greek; do
  mkdir -p "$JL/$mod"
  cat > "$JL/$mod/build.gradle" <<'GRADLE'
apply plugin: 'com.android.library'

android {
    namespace 'ru.noties.jlatexmath.font'
    compileSdk 36
    buildToolsVersion '36.0.0'
    defaultConfig {
        minSdk 21
        missingDimensionStrategy 'minApi', 'afat'
    }
}

repositories { google(); mavenCentral() }
GRADLE
done

# jlatexmath inner settings.gradle
cat > "$JL/settings.gradle" <<'GRADLE'
rootProject.name = 'jlatexmath-parent'
include ':jlatexmath'
include ':jlatexmath-font-cyrillic'
include ':jlatexmath-font-greek'
GRADLE

# point :jlatexmath to the actual library module
if ! grep -q "jlatexmath/jlatexmath/jlatexmath'" settings.gradle; then
  sed -i "s#project(':jlatexmath').projectDir = file('TMessagesProj/lib/jlatexmath/jlatexmath')#project(':jlatexmath').projectDir = file('TMessagesProj/lib/jlatexmath/jlatexmath/jlatexmath')#" settings.gradle || true
fi

echo "jlatexmath patched successfully"
grep -n "missingDimensionStrategy" "$JL/jlatexmath/build.gradle" || true
grep -n "jlatexmath" settings.gradle
