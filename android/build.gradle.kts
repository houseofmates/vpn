allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)

    // Force compileSdk 35 on all android subprojects (dynamic – no imports needed)
    afterEvaluate {
        try {
            val androidExt = extensions.getByName("android")
            // Use setProperty to avoid compile-time type requirements
            androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(androidExt, 35)
        } catch (_: Exception) {
            // ignore if no android extension
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
