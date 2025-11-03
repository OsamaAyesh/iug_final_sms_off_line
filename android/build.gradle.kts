// =====================================
// Root Gradle file - build.gradle.kts
// =====================================

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ صيغة Kotlin DSL الصحيحة
        classpath("com.google.gms:google-services:4.4.2")
        classpath("com.android.tools.build:gradle:8.7.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ تعديل مسار build directory (خاص بفلاتر)
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

// ✅ مهمة تنظيف المشروع
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
