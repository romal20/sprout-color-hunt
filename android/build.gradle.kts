allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force all subprojects (plugins) to compile against SDK 36.
// This resolves AAR metadata errors from older plugins that declare
// compileSdk 31/33 but depend on androidx libraries that require 34+.
subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            val androidExt = extensions.getByType(com.android.build.gradle.BaseExtension::class)
            if (androidExt.compileSdkVersion != "android-36") {
                androidExt.compileSdkVersion(36)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
