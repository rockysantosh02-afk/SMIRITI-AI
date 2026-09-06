// Bridge legacy jcenter() calls from older plugins (e.g. speech_to_text) to mavenCentral() under Gradle 9
try {
    val registry = groovy.lang.GroovySystem.getMetaClassRegistry()
    val repoClasses = listOf(
        Class.forName("org.gradle.api.artifacts.dsl.RepositoryHandler"),
        Class.forName("org.gradle.api.internal.artifacts.dsl.DefaultRepositoryHandler")
    )
    for (clazz in repoClasses) {
        val metaClass = registry.getMetaClass(clazz)
        val emc = if (metaClass is groovy.lang.ExpandoMetaClass) {
            metaClass
        } else {
            groovy.lang.ExpandoMetaClass(clazz, false, true).apply {
                initialize()
                registry.setMetaClass(clazz, this)
            }
        }
        emc.registerInstanceMethod("jcenter", object : groovy.lang.Closure<Any>(null) {
            fun doCall(): Any? {
                return (delegate as? org.gradle.api.artifacts.dsl.RepositoryHandler)?.mavenCentral()
            }
        })
    }
} catch (e: Throwable) {
    println("Note: jcenter bridge registration: $e")
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("com.android.library") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

rootProject.name = "dashboard_app"
include(":app")
