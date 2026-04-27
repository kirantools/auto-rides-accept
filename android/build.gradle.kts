plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.cashfree.com/release") }
    }
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.compileSdkVersion(35)
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions { jvmTarget = "17" }
    }

    plugins.withType<com.android.build.gradle.BasePlugin>().configureEach {
        project.extensions.configure<com.android.build.gradle.BaseExtension> {
            if (namespace == null) {
                // Targeted fix for Cashfree legacy manifest
                if (project.name.contains("cashfree")) {
                    namespace = "com.cashfree.cashfree_pg"
                } else {
                    namespace = "com.swayam.swayam_universal.${project.name}"
                }
            }
        }
    }

    configurations.all {
        resolutionStrategy {
            force("com.android.volley:volley:1.2.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
